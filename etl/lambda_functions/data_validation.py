"""
AWS Lambda Function: Data Validation

This function validates incoming data files in S3 and triggers
appropriate ETL workflows based on data quality checks.

Author: Data Engineering Team
"""

import json
import boto3
import pandas as pd
from datetime import datetime
import logging
from typing import Dict, List, Any
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3', region_name='ap-south-1')
glue_client = boto3.client('glue', region_name='ap-south-1')
sns_client = boto3.client('sns', region_name='ap-south-1')

class DataValidator:
    def __init__(self):
        self.validation_rules = {
            'customers': {
                'required_columns': ['customer_id', 'email', 'registration_date'],
                'max_null_percentage': 0.05,
                'expected_row_count_min': 100
            },
            'products': {
                'required_columns': ['product_id', 'product_name', 'price'],
                'max_null_percentage': 0.05,
                'expected_row_count_min': 50
            },
            'orders': {
                'required_columns': ['order_id', 'customer_id', 'order_date', 'total_amount'],
                'max_null_percentage': 0.02,
                'expected_row_count_min': 10
            },
            'order_items': {
                'required_columns': ['order_item_id', 'order_id', 'product_id', 'quantity'],
                'max_null_percentage': 0.02,
                'expected_row_count_min': 10
            }
        }
    
    def extract_table_name(self, s3_key: str) -> str:
        """Extract table name from S3 key"""
        # Assuming format: data/table_name/file.csv
        parts = s3_key.split('/')
        if len(parts) >= 2:
            return parts[-2]  # Get the directory name
        return 'unknown'
    
    def read_s3_file(self, bucket: str, key: str) -> pd.DataFrame:
        """Read CSV file from S3"""
        try:
            response = s3_client.get_object(Bucket=bucket, Key=key)
            df = pd.read_csv(response['Body'])
            logger.info(f"Successfully read {len(df)} rows from s3://{bucket}/{key}")
            return df
        except Exception as e:
            logger.error(f"Error reading file s3://{bucket}/{key}: {str(e)}")
            raise
    
    def validate_schema(self, df: pd.DataFrame, table_name: str) -> List[str]:
        """Validate data schema"""
        issues = []
        
        if table_name not in self.validation_rules:
            issues.append(f"No validation rules defined for table: {table_name}")
            return issues
        
        rules = self.validation_rules[table_name]
        
        # Check required columns
        missing_columns = set(rules['required_columns']) - set(df.columns)
        if missing_columns:
            issues.append(f"Missing required columns: {missing_columns}")
        
        return issues
    
    def validate_data_quality(self, df: pd.DataFrame, table_name: str) -> List[str]:
        """Validate data quality"""
        issues = []
        
        if table_name not in self.validation_rules:
            return issues
        
        rules = self.validation_rules[table_name]
        
        # Check row count
        if len(df) < rules['expected_row_count_min']:
            issues.append(f"Row count {len(df)} below minimum {rules['expected_row_count_min']}")
        
        # Check null percentages
        for col in rules['required_columns']:
            if col in df.columns:
                null_percentage = df[col].isnull().sum() / len(df)
                if null_percentage > rules['max_null_percentage']:
                    issues.append(f"Column {col} has {null_percentage:.2%} null values (max: {rules['max_null_percentage']:.2%})")
        
        # Table-specific validations
        if table_name == 'customers':
            # Validate email format
            if 'email' in df.columns:
                invalid_emails = df[~df['email'].str.contains('@', na=False)]
                if len(invalid_emails) > 0:
                    issues.append(f"Found {len(invalid_emails)} invalid email addresses")
        
        elif table_name == 'products':
            # Validate price values
            if 'price' in df.columns:
                negative_prices = df[df['price'] <= 0]
                if len(negative_prices) > 0:
                    issues.append(f"Found {len(negative_prices)} products with non-positive prices")
        
        elif table_name == 'orders':
            # Validate order amounts
            if 'total_amount' in df.columns:
                negative_amounts = df[df['total_amount'] <= 0]
                if len(negative_amounts) > 0:
                    issues.append(f"Found {len(negative_amounts)} orders with non-positive amounts")
        
        return issues
    
    def validate_file(self, bucket: str, key: str) -> Dict[str, Any]:
        """Validate a single file"""
        table_name = self.extract_table_name(key)
        
        validation_result = {
            'file': f"s3://{bucket}/{key}",
            'table_name': table_name,
            'timestamp': datetime.utcnow().isoformat(),
            'status': 'PASSED',
            'issues': [],
            'row_count': 0,
            'column_count': 0
        }
        
        try:
            # Read the file
            df = self.read_s3_file(bucket, key)
            validation_result['row_count'] = len(df)
            validation_result['column_count'] = len(df.columns)
            
            # Validate schema
            schema_issues = self.validate_schema(df, table_name)
            validation_result['issues'].extend(schema_issues)
            
            # Validate data quality
            quality_issues = self.validate_data_quality(df, table_name)
            validation_result['issues'].extend(quality_issues)
            
            # Set overall status
            if validation_result['issues']:
                validation_result['status'] = 'FAILED'
                logger.warning(f"Validation failed for {key}: {validation_result['issues']}")
            else:
                logger.info(f"Validation passed for {key}")
        
        except Exception as e:
            validation_result['status'] = 'ERROR'
            validation_result['issues'].append(f"Validation error: {str(e)}")
            logger.error(f"Validation error for {key}: {str(e)}")
        
        return validation_result
    
    def trigger_etl_job(self, job_name: str, parameters: Dict[str, str]) -> str:
        """Trigger AWS Glue ETL job"""
        try:
            response = glue_client.start_job_run(
                JobName=job_name,
                Arguments=parameters
            )
            job_run_id = response['JobRunId']
            logger.info(f"Started Glue job {job_name} with run ID: {job_run_id}")
            return job_run_id
        except Exception as e:
            logger.error(f"Error starting Glue job {job_name}: {str(e)}")
            raise
    
    def send_notification(self, topic_arn: str, subject: str, message: str):
        """Send SNS notification"""
        try:
            sns_client.publish(
                TopicArn=topic_arn,
                Subject=subject,
                Message=message
            )
            logger.info(f"Sent notification: {subject}")
        except Exception as e:
            logger.error(f"Error sending notification: {str(e)}")

def lambda_handler(event, context):
    """Lambda handler function"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    validator = DataValidator()
    results = []
    
    try:
        # Process S3 events
        for record in event.get('Records', []):
            if record.get('eventSource') == 'aws:s3':
                bucket = record['s3']['bucket']['name']
                key = record['s3']['object']['key']
                
                # Skip non-CSV files
                if not key.endswith('.csv'):
                    logger.info(f"Skipping non-CSV file: {key}")
                    continue
                
                # Validate the file
                result = validator.validate_file(bucket, key)
                results.append(result)
                
                # Trigger ETL job if validation passed
                if result['status'] == 'PASSED':
                    job_name = os.environ.get('GLUE_JOB_NAME', 'ecommerce-dwh-data-processing')
                    parameters = {
                        '--raw_data_bucket': bucket,
                        '--processed_data_bucket': os.environ.get('PROCESSED_DATA_BUCKET', ''),
                        '--database_name': os.environ.get('GLUE_DATABASE_NAME', 'ecommerce_catalog')
                    }
                    
                    try:
                        job_run_id = validator.trigger_etl_job(job_name, parameters)
                        result['etl_job_run_id'] = job_run_id
                    except Exception as e:
                        logger.error(f"Failed to trigger ETL job: {str(e)}")
                
                # Send notification for failed validations
                elif result['status'] == 'FAILED':
                    topic_arn = os.environ.get('SNS_TOPIC_ARN')
                    if topic_arn:
                        subject = f"Data Validation Failed: {result['table_name']}"
                        message = f"File: {result['file']}\nIssues: {result['issues']}"
                        validator.send_notification(topic_arn, subject, message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data validation completed',
                'results': results
            })
        }
    
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
