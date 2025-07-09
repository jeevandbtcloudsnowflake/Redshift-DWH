#!/usr/bin/env python3
"""
Automated ETL Pipeline Runner

This script orchestrates the complete ETL pipeline:
1. Starts Glue crawler
2. Waits for crawler completion
3. Runs data processing job
4. Runs data quality job
5. Sends notifications

Usage:
    python run_etl_pipeline.py --environment dev
    python run_etl_pipeline.py --environment dev --skip-crawler
"""

import boto3
import time
import argparse
import logging
import json
from datetime import datetime
from typing import Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ETLPipelineRunner:
    def __init__(self, environment: str, region: str = 'ap-south-1'):
        self.environment = environment
        self.region = region
        self.project_name = 'ecommerce-dwh'
        
        # Initialize AWS clients
        self.glue_client = boto3.client('glue', region_name=region)
        self.sns_client = boto3.client('sns', region_name=region)
        
        # Resource names
        self.crawler_name = f"{self.project_name}-{environment}-raw-data-crawler"
        self.processing_job_name = f"{self.project_name}-{environment}-data-processing"
        self.quality_job_name = f"{self.project_name}-{environment}-data-quality"
        
    def start_crawler(self) -> bool:
        """Start the Glue crawler and wait for completion"""
        try:
            logger.info(f"Starting crawler: {self.crawler_name}")
            
            # Start the crawler
            self.glue_client.start_crawler(Name=self.crawler_name)
            
            # Wait for crawler to complete
            while True:
                response = self.glue_client.get_crawler(Name=self.crawler_name)
                state = response['Crawler']['State']
                
                logger.info(f"Crawler state: {state}")
                
                if state == 'READY':
                    logger.info("Crawler completed successfully")
                    return True
                elif state in ['STOPPING', 'FAILED']:
                    logger.error(f"Crawler failed with state: {state}")
                    return False
                
                time.sleep(30)  # Wait 30 seconds before checking again
                
        except Exception as e:
            logger.error(f"Error starting crawler: {str(e)}")
            return False
    
    def run_glue_job(self, job_name: str, arguments: Dict[str, str] = None) -> bool:
        """Run a Glue job and wait for completion"""
        try:
            logger.info(f"Starting Glue job: {job_name}")
            
            # Prepare job arguments
            job_args = arguments or {}
            
            # Start the job
            response = self.glue_client.start_job_run(
                JobName=job_name,
                Arguments=job_args
            )
            
            job_run_id = response['JobRunId']
            logger.info(f"Job run ID: {job_run_id}")
            
            # Wait for job to complete
            while True:
                response = self.glue_client.get_job_run(
                    JobName=job_name,
                    RunId=job_run_id
                )
                
                state = response['JobRun']['JobRunState']
                logger.info(f"Job {job_name} state: {state}")
                
                if state == 'SUCCEEDED':
                    logger.info(f"Job {job_name} completed successfully")
                    return True
                elif state in ['FAILED', 'STOPPED', 'TIMEOUT']:
                    logger.error(f"Job {job_name} failed with state: {state}")
                    return False
                
                time.sleep(60)  # Wait 1 minute before checking again
                
        except Exception as e:
            logger.error(f"Error running job {job_name}: {str(e)}")
            return False
    
    def send_notification(self, subject: str, message: str, success: bool = True):
        """Send SNS notification"""
        try:
            # Try to find SNS topic (optional)
            topic_name = f"{self.project_name}-{self.environment}-notifications"
            
            # For now, just log the notification
            status = "SUCCESS" if success else "FAILURE"
            logger.info(f"NOTIFICATION [{status}] - {subject}: {message}")
            
            # Uncomment below if you have SNS topic configured
            # response = self.sns_client.publish(
            #     TopicArn=f"arn:aws:sns:{self.region}:ACCOUNT_ID:{topic_name}",
            #     Subject=subject,
            #     Message=message
            # )
            
        except Exception as e:
            logger.warning(f"Could not send notification: {str(e)}")
    
    def run_pipeline(self, skip_crawler: bool = False) -> bool:
        """Run the complete ETL pipeline"""
        start_time = datetime.now()
        logger.info(f"Starting ETL pipeline for environment: {self.environment}")
        
        try:
            # Step 1: Run crawler (unless skipped)
            if not skip_crawler:
                if not self.start_crawler():
                    self.send_notification(
                        "ETL Pipeline Failed",
                        "Crawler failed to complete successfully",
                        success=False
                    )
                    return False
            else:
                logger.info("Skipping crawler as requested")
            
            # Step 2: Run data processing job
            processing_args = {
                "--raw_data_bucket": f"{self.project_name}-{self.environment}-raw-data",
                "--processed_data_bucket": f"{self.project_name}-{self.environment}-processed-data",
                "--database_name": f"ecommerce_catalog_{self.environment}"
            }
            
            if not self.run_glue_job(self.processing_job_name, processing_args):
                self.send_notification(
                    "ETL Pipeline Failed",
                    "Data processing job failed",
                    success=False
                )
                return False
            
            # Step 3: Run data quality job
            quality_args = {
                "--processed_data_bucket": f"{self.project_name}-{self.environment}-processed-data",
                "--database_name": f"ecommerce_catalog_{self.environment}"
            }
            
            if not self.run_glue_job(self.quality_job_name, quality_args):
                self.send_notification(
                    "ETL Pipeline Failed",
                    "Data quality job failed",
                    success=False
                )
                return False
            
            # Success!
            end_time = datetime.now()
            duration = end_time - start_time
            
            success_message = f"""
ETL Pipeline completed successfully!

Environment: {self.environment}
Start time: {start_time.strftime('%Y-%m-%d %H:%M:%S')}
End time: {end_time.strftime('%Y-%m-%d %H:%M:%S')}
Duration: {duration}

Jobs completed:
- Crawler: {self.crawler_name}
- Data Processing: {self.processing_job_name}
- Data Quality: {self.quality_job_name}
            """
            
            self.send_notification(
                "ETL Pipeline Success",
                success_message,
                success=True
            )
            
            logger.info("ETL pipeline completed successfully!")
            return True
            
        except Exception as e:
            logger.error(f"ETL pipeline failed: {str(e)}")
            self.send_notification(
                "ETL Pipeline Failed",
                f"Pipeline failed with error: {str(e)}",
                success=False
            )
            return False

def main():
    parser = argparse.ArgumentParser(description='Run ETL Pipeline')
    parser.add_argument(
        '--environment',
        required=True,
        choices=['dev', 'staging', 'prod'],
        help='Environment to run pipeline for'
    )
    parser.add_argument(
        '--skip-crawler',
        action='store_true',
        help='Skip the crawler step'
    )
    parser.add_argument(
        '--region',
        default='ap-south-1',
        help='AWS region'
    )
    
    args = parser.parse_args()
    
    # Run the pipeline
    runner = ETLPipelineRunner(args.environment, args.region)
    success = runner.run_pipeline(skip_crawler=args.skip_crawler)
    
    if success:
        logger.info("Pipeline completed successfully!")
        exit(0)
    else:
        logger.error("Pipeline failed!")
        exit(1)

if __name__ == "__main__":
    main()
