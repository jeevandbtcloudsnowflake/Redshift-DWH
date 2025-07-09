@echo off
echo ========================================
echo Uploading ETL Scripts to S3
echo ========================================

REM Get the scripts bucket name from Terraform output
echo Getting S3 bucket name...
cd infrastructure\environments\dev

REM Extract bucket name (you'll need to replace this with the actual bucket name)
REM For now, we'll use a placeholder - you can get the actual name from AWS console
set SCRIPTS_BUCKET=ecommerce-dwh-dev-scripts-xxxxxxxx

echo Scripts bucket: %SCRIPTS_BUCKET%
echo.

REM Go back to project root
cd ..\..\..

echo Uploading Glue ETL scripts...
aws s3 cp etl\glue_jobs\data_processing.py s3://%SCRIPTS_BUCKET%/glue_jobs/data_processing.py --region ap-south-1
aws s3 cp etl\glue_jobs\data_quality.py s3://%SCRIPTS_BUCKET%/glue_jobs/data_quality.py --region ap-south-1

echo.
echo Verifying uploads...
aws s3 ls s3://%SCRIPTS_BUCKET%/glue_jobs/ --region ap-south-1

echo.
echo ========================================
echo Script upload completed!
echo ========================================
echo.
echo Next steps:
echo 1. Update the Glue job script locations in AWS console
echo 2. Generate sample data
echo 3. Run the ETL pipeline
echo.
pause
