"""
AWS Glue ETL Job: Data Quality Validation

This job performs comprehensive data quality checks on processed data
and generates quality reports for monitoring and alerting.

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
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataQualityValidator:
    def __init__(self, glue_context, spark_context, job):
        self.glueContext = glue_context
        self.spark = glue_context.spark_session
        self.sc = spark_context
        self.job = job
        
        # Quality thresholds
        self.thresholds = {
            'completeness': 0.95,
            'accuracy': 0.98,
            'consistency': 0.99,
            'validity': 0.97
        }
        
    def read_processed_data(self, database_name, table_name):
        """Read processed data from Glue catalog"""
        try:
            dynamic_frame = self.glueContext.create_dynamic_frame.from_catalog(
                database=database_name,
                table_name=table_name,
                transformation_ctx=f"read_{table_name}"
            )
            logger.info(f"Successfully read {dynamic_frame.count()} records from {table_name}")
            return dynamic_frame.toDF()
        except Exception as e:
            logger.error(f"Error reading {table_name}: {str(e)}")
            return None
    
    def check_completeness(self, df, table_name, required_columns):
        """Check data completeness"""
        logger.info(f"Checking completeness for {table_name}")
        
        results = {
            'table_name': table_name,
            'check_type': 'completeness',
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        total_rows = df.count()
        
        for column in required_columns:
            if column in df.columns:
                null_count = df.filter(F.col(column).isNull()).count()
                completeness_rate = (total_rows - null_count) / total_rows if total_rows > 0 else 0
                
                results['metrics'][f'{column}_completeness'] = completeness_rate
                
                if completeness_rate < self.thresholds['completeness']:
                    results['issues'].append(
                        f"Column {column} completeness {completeness_rate:.2%} below threshold"
                    )
                    results['passed'] = False
        
        return results
    
    def check_data_freshness(self, df, table_name, date_column='created_at'):
        """Check data freshness"""
        logger.info(f"Checking data freshness for {table_name}")
        
        results = {
            'table_name': table_name,
            'check_type': 'freshness',
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        if date_column in df.columns:
            # Get the latest record timestamp
            latest_record = df.agg(F.max(date_column).alias('latest')).collect()[0]['latest']
            
            if latest_record:
                # Calculate hours since latest record
                current_time = datetime.utcnow()
                if isinstance(latest_record, str):
                    latest_record = datetime.fromisoformat(latest_record.replace('Z', '+00:00'))
                
                hours_since_latest = (current_time - latest_record.replace(tzinfo=None)).total_seconds() / 3600
                
                results['metrics']['hours_since_latest'] = hours_since_latest
                
                # Alert if data is older than 24 hours
                if hours_since_latest > 24:
                    results['issues'].append(f"Data is {hours_since_latest:.1f} hours old")
                    results['passed'] = False
        
        return results
    
    def check_data_volume(self, df, table_name, expected_min_rows=100):
        """Check data volume"""
        logger.info(f"Checking data volume for {table_name}")
        
        results = {
            'table_name': table_name,
            'check_type': 'volume',
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        row_count = df.count()
        results['metrics']['row_count'] = row_count
        
        if row_count < expected_min_rows:
            results['issues'].append(f"Row count {row_count} below expected minimum {expected_min_rows}")
            results['passed'] = False
        
        return results
    
    def check_business_rules(self, df, table_name):
        """Check business-specific rules"""
        logger.info(f"Checking business rules for {table_name}")
        
        results = {
            'table_name': table_name,
            'check_type': 'business_rules',
            'timestamp': datetime.utcnow().isoformat(),
            'passed': True,
            'issues': [],
            'metrics': {}
        }
        
        if table_name == 'customers':
            # Check for valid email domains
            if 'email' in df.columns:
                invalid_emails = df.filter(~F.col('email').rlike(r'^[^@]+@[^@]+\.[^@]+$')).count()
                results['metrics']['invalid_email_count'] = invalid_emails
                
                if invalid_emails > 0:
                    results['issues'].append(f"Found {invalid_emails} invalid email addresses")
                    results['passed'] = False
        
        elif table_name == 'products':
            # Check for reasonable price ranges
            if 'price' in df.columns:
                negative_prices = df.filter(F.col('price') <= 0).count()
                extreme_prices = df.filter(F.col('price') > 10000).count()
                
                results['metrics']['negative_price_count'] = negative_prices
                results['metrics']['extreme_price_count'] = extreme_prices
                
                if negative_prices > 0:
                    results['issues'].append(f"Found {negative_prices} products with negative prices")
                    results['passed'] = False
                
                if extreme_prices > 0:
                    results['issues'].append(f"Found {extreme_prices} products with extreme prices (>$10,000)")
        
        elif table_name == 'orders':
            # Check for valid order amounts
            if 'total_amount' in df.columns:
                negative_amounts = df.filter(F.col('total_amount') <= 0).count()
                extreme_amounts = df.filter(F.col('total_amount') > 50000).count()
                
                results['metrics']['negative_amount_count'] = negative_amounts
                results['metrics']['extreme_amount_count'] = extreme_amounts
                
                if negative_amounts > 0:
                    results['issues'].append(f"Found {negative_amounts} orders with negative amounts")
                    results['passed'] = False
        
        return results
    
    def generate_quality_report(self, all_results):
        """Generate comprehensive quality report"""
        report = {
            'timestamp': datetime.utcnow().isoformat(),
            'overall_status': 'PASSED',
            'summary': {
                'total_checks': len(all_results),
                'passed_checks': 0,
                'failed_checks': 0
            },
            'details': all_results
        }
        
        for result in all_results:
            if result['passed']:
                report['summary']['passed_checks'] += 1
            else:
                report['summary']['failed_checks'] += 1
                report['overall_status'] = 'FAILED'
        
        report['summary']['pass_rate'] = (
            report['summary']['passed_checks'] / report['summary']['total_checks']
            if report['summary']['total_checks'] > 0 else 0
        )
        
        return report
    
    def save_quality_report(self, report, output_bucket):
        """Save quality report to S3"""
        try:
            import json
            
            # Convert report to JSON
            report_json = json.dumps(report, indent=2, default=str)
            
            # Save to S3
            s3_client = boto3.client('s3')
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            key = f"quality_reports/data_quality_report_{timestamp}.json"
            
            s3_client.put_object(
                Bucket=output_bucket,
                Key=key,
                Body=report_json,
                ContentType='application/json'
            )
            
            logger.info(f"Quality report saved to s3://{output_bucket}/{key}")
            
        except Exception as e:
            logger.error(f"Error saving quality report: {str(e)}")

def main():
    """Main data quality validation process"""
    # Get job parameters
    args = getResolvedOptions(sys.argv, [
        'JOB_NAME',
        'processed_data_bucket',
        'database_name'
    ])
    
    # Initialize Glue context
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    
    # Initialize validator
    validator = DataQualityValidator(glueContext, sc, job)
    
    try:
        logger.info("Starting data quality validation")
        
        all_results = []
        
        # Define tables and their required columns
        tables_config = {
            'customers': ['customer_id', 'email', 'registration_date'],
            'products': ['product_id', 'product_name', 'price'],
            'orders': ['order_id', 'customer_id', 'order_date', 'total_amount']
        }
        
        # Run quality checks for each table
        for table_name, required_columns in tables_config.items():
            logger.info(f"Processing quality checks for {table_name}")
            
            # Read processed data
            df = validator.read_processed_data(args['database_name'], table_name)
            
            if df is not None:
                # Run all quality checks
                completeness_result = validator.check_completeness(df, table_name, required_columns)
                freshness_result = validator.check_data_freshness(df, table_name)
                volume_result = validator.check_data_volume(df, table_name)
                business_rules_result = validator.check_business_rules(df, table_name)
                
                all_results.extend([
                    completeness_result,
                    freshness_result,
                    volume_result,
                    business_rules_result
                ])
        
        # Generate and save quality report
        quality_report = validator.generate_quality_report(all_results)
        validator.save_quality_report(quality_report, args['processed_data_bucket'])
        
        # Log summary
        logger.info(f"Data quality validation completed")
        logger.info(f"Overall status: {quality_report['overall_status']}")
        logger.info(f"Pass rate: {quality_report['summary']['pass_rate']:.2%}")
        
        if quality_report['overall_status'] == 'FAILED':
            logger.warning("Some quality checks failed - review the detailed report")
        
    except Exception as e:
        logger.error(f"Data quality validation failed: {str(e)}")
        raise
    finally:
        job.commit()

if __name__ == "__main__":
    main()
