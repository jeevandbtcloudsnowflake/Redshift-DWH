"""
AWS Glue ETL Job: Data Processing

This job processes raw e-commerce data from S3, applies transformations,
performs data quality checks, and loads clean data to Redshift.

Author: Data Engineering Team
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F
from pyspark.sql.types import *
import boto3
from datetime import datetime, timedelta
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataProcessor:
    def __init__(self, glue_context, spark_context, job, job_args=None):
        self.glueContext = glue_context
        self.spark = glue_context.spark_session
        self.sc = spark_context
        self.job = job
        self.args = job_args or {}
        
    def read_from_s3(self, database_name, table_name, transformation_ctx):
        """Read data from S3 using Glue Data Catalog"""
        try:
            # First try to read from catalog
            dynamic_frame = self.glueContext.create_dynamic_frame.from_catalog(
                database=database_name,
                table_name=table_name,
                transformation_ctx=transformation_ctx
            )
            logger.info(f"Successfully read {dynamic_frame.count()} records from {table_name}")
            return dynamic_frame
        except Exception as e:
            logger.error(f"Error reading from catalog {table_name}: {str(e)}")
            logger.info(f"Attempting to read directly from S3...")

            # Fallback: read directly from S3
            try:
                # Get bucket name from job arguments
                raw_bucket = self.args.get('raw_data_bucket', '')
                s3_path = f"s3://{raw_bucket}/data/{table_name}.csv"
                dynamic_frame = self.glueContext.create_dynamic_frame.from_options(
                    connection_type="s3",
                    connection_options={"paths": [s3_path]},
                    format="csv",
                    format_options={"withHeader": True},
                    transformation_ctx=transformation_ctx
                )
                logger.info(f"Successfully read {dynamic_frame.count()} records from S3 directly")
                return dynamic_frame
            except Exception as s3_error:
                logger.error(f"Error reading from S3 {s3_path}: {str(s3_error)}")
                raise
    
    def validate_data_quality(self, df, table_name):
        """Perform data quality checks"""
        logger.info(f"Starting data quality validation for {table_name}")
        
        quality_issues = []
        
        # Check for null values in critical columns
        critical_columns = {
            'customers': ['customer_id', 'email', 'registration_date'],
            'products': ['product_id', 'product_name', 'price'],
            'orders': ['order_id', 'customer_id', 'order_date', 'total_amount'],
            'order_items': ['order_item_id', 'order_id', 'product_id', 'quantity']
        }
        
        if table_name in critical_columns:
            for col in critical_columns[table_name]:
                if col in df.columns:
                    null_count = df.filter(F.col(col).isNull()).count()
                    if null_count > 0:
                        quality_issues.append(f"Found {null_count} null values in {col}")
        
        # Check for duplicate records
        total_count = df.count()
        if table_name == 'customers':
            distinct_count = df.select('customer_id').distinct().count()
        elif table_name == 'products':
            distinct_count = df.select('product_id').distinct().count()
        elif table_name == 'orders':
            distinct_count = df.select('order_id').distinct().count()
        elif table_name == 'order_items':
            distinct_count = df.select('order_item_id').distinct().count()
        else:
            distinct_count = total_count
            
        if distinct_count != total_count:
            quality_issues.append(f"Found {total_count - distinct_count} duplicate records")
        
        # Log quality issues
        if quality_issues:
            logger.warning(f"Data quality issues in {table_name}: {quality_issues}")
        else:
            logger.info(f"Data quality validation passed for {table_name}")
        
        return quality_issues
    
    def transform_customers(self, customers_df):
        """Transform customer data"""
        logger.info("Transforming customer data")
        
        # Data cleaning and transformations
        transformed_df = customers_df.withColumn(
            "full_name", 
            F.concat_ws(" ", F.col("first_name"), F.col("last_name"))
        ).withColumn(
            "age",
            F.floor(F.datediff(F.current_date(), F.col("date_of_birth")) / 365.25)
        ).withColumn(
            "customer_lifetime_months",
            F.floor(F.datediff(F.current_date(), F.col("registration_date")) / 30)
        ).withColumn(
            "email_domain",
            F.split(F.col("email"), "@").getItem(1)
        ).withColumn(
            "processed_at",
            F.current_timestamp()
        )
        
        # Filter out invalid records
        transformed_df = transformed_df.filter(
            (F.col("customer_id").isNotNull()) &
            (F.col("email").isNotNull()) &
            (F.col("registration_date").isNotNull())
        )
        
        return transformed_df
    
    def transform_products(self, products_df):
        """Transform product data"""
        logger.info("Transforming product data")
        
        # Calculate profit margin
        transformed_df = products_df.withColumn(
            "profit_margin",
            F.when(F.col("cost").isNotNull() & (F.col("cost") > 0),
                   (F.col("price") - F.col("cost")) / F.col("price")
            ).otherwise(None)
        ).withColumn(
            "price_category",
            F.when(F.col("price") < 25, "Budget")
            .when(F.col("price") < 100, "Mid-range")
            .otherwise("Premium")
        ).withColumn(
            "stock_status",
            F.when(F.col("stock_quantity") == 0, "Out of Stock")
            .when(F.col("stock_quantity") <= F.col("reorder_level"), "Low Stock")
            .otherwise("In Stock")
        ).withColumn(
            "processed_at",
            F.current_timestamp()
        )
        
        # Filter out invalid records
        transformed_df = transformed_df.filter(
            (F.col("product_id").isNotNull()) &
            (F.col("product_name").isNotNull()) &
            (F.col("price").isNotNull()) &
            (F.col("price") > 0)
        )
        
        return transformed_df
    
    def transform_orders(self, orders_df):
        """Transform order data"""
        logger.info("Transforming order data")
        
        # Calculate derived fields
        transformed_df = orders_df.withColumn(
            "order_year",
            F.year(F.col("order_date"))
        ).withColumn(
            "order_month",
            F.month(F.col("order_date"))
        ).withColumn(
            "order_quarter",
            F.quarter(F.col("order_date"))
        ).withColumn(
            "order_day_of_week",
            F.dayofweek(F.col("order_date"))
        ).withColumn(
            "days_to_ship",
            F.when(F.col("shipped_date").isNotNull(),
                   F.datediff(F.col("shipped_date"), F.col("order_date"))
            ).otherwise(None)
        ).withColumn(
            "days_to_deliver",
            F.when(F.col("delivered_date").isNotNull(),
                   F.datediff(F.col("delivered_date"), F.col("order_date"))
            ).otherwise(None)
        ).withColumn(
            "is_weekend_order",
            F.when(F.col("order_day_of_week").isin([1, 7]), True).otherwise(False)
        ).withColumn(
            "processed_at",
            F.current_timestamp()
        )
        
        # Filter out invalid records
        transformed_df = transformed_df.filter(
            (F.col("order_id").isNotNull()) &
            (F.col("customer_id").isNotNull()) &
            (F.col("order_date").isNotNull()) &
            (F.col("total_amount").isNotNull()) &
            (F.col("total_amount") > 0)
        )
        
        return transformed_df

    def write_to_s3(self, dynamic_frame, output_path, format_type="parquet"):
        """Write data to S3"""
        try:
            self.glueContext.write_dynamic_frame.from_options(
                frame=dynamic_frame,
                connection_type="s3",
                connection_options={
                    "path": output_path,
                    "partitionKeys": []
                },
                format=format_type,
                transformation_ctx=f"write_{format_type}"
            )
            logger.info(f"Successfully wrote data to {output_path}")
        except Exception as e:
            logger.error(f"Error writing to {output_path}: {str(e)}")
            raise

    def write_to_redshift(self, dynamic_frame, table_name, redshift_connection):
        """Write data to Redshift"""
        try:
            self.glueContext.write_dynamic_frame.from_jdbc_conf(
                frame=dynamic_frame,
                catalog_connection=redshift_connection,
                connection_options={
                    "dbtable": table_name,
                    "database": "ecommerce_dwh"
                },
                redshift_tmp_dir="s3://your-temp-bucket/redshift-temp/",
                transformation_ctx=f"write_redshift_{table_name}"
            )
            logger.info(f"Successfully wrote data to Redshift table {table_name}")
        except Exception as e:
            logger.error(f"Error writing to Redshift table {table_name}: {str(e)}")
            raise

def main():
    """Main ETL process"""
    # Get job parameters
    args = getResolvedOptions(sys.argv, [
        'JOB_NAME',
        'raw_data_bucket',
        'processed_data_bucket',
        'database_name'
    ])

    # Initialize Glue context
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Initialize data processor
    processor = DataProcessor(glueContext, sc, job, args)

    try:
        logger.info("Starting ETL job")

        # Read raw data
        customers_df = processor.read_from_s3(
            args['database_name'],
            'customers',
            'read_customers'
        ).toDF()

        products_df = processor.read_from_s3(
            args['database_name'],
            'products',
            'read_products'
        ).toDF()

        orders_df = processor.read_from_s3(
            args['database_name'],
            'orders',
            'read_orders'
        ).toDF()

        # Validate data quality
        processor.validate_data_quality(customers_df, 'customers')
        processor.validate_data_quality(products_df, 'products')
        processor.validate_data_quality(orders_df, 'orders')

        # Transform data
        customers_transformed = processor.transform_customers(customers_df)
        products_transformed = processor.transform_products(products_df)
        orders_transformed = processor.transform_orders(orders_df)

        # Convert back to DynamicFrames
        customers_dynamic = DynamicFrame.fromDF(
            customers_transformed,
            glueContext,
            "customers_transformed"
        )
        products_dynamic = DynamicFrame.fromDF(
            products_transformed,
            glueContext,
            "products_transformed"
        )
        orders_dynamic = DynamicFrame.fromDF(
            orders_transformed,
            glueContext,
            "orders_transformed"
        )

        # Write processed data to S3
        processor.write_to_s3(
            customers_dynamic,
            f"s3://{args['processed_data_bucket']}/customers/",
            "parquet"
        )
        processor.write_to_s3(
            products_dynamic,
            f"s3://{args['processed_data_bucket']}/products/",
            "parquet"
        )
        processor.write_to_s3(
            orders_dynamic,
            f"s3://{args['processed_data_bucket']}/orders/",
            "parquet"
        )

        logger.info("ETL job completed successfully")

    except Exception as e:
        logger.error(f"ETL job failed: {str(e)}")
        raise
    finally:
        job.commit()

if __name__ == "__main__":
    main()
