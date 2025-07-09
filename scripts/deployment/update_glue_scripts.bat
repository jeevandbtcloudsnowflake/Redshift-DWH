@echo off
echo ========================================
echo Updating Glue ETL Scripts
echo ========================================

REM Replace with your actual scripts bucket name
set SCRIPTS_BUCKET=ecommerce-dwh-dev-scripts-xxxxxxxx

echo Scripts bucket: %SCRIPTS_BUCKET%
echo.

echo Uploading updated Glue ETL scripts...
aws s3 cp etl\glue_jobs\data_processing.py s3://%SCRIPTS_BUCKET%/glue_jobs/data_processing.py --region ap-south-1
aws s3 cp etl\glue_jobs\data_quality.py s3://%SCRIPTS_BUCKET%/glue_jobs/data_quality.py --region ap-south-1

echo.
echo Verifying uploads...
aws s3 ls s3://%SCRIPTS_BUCKET%/glue_jobs/ --region ap-south-1

echo.
echo ========================================
echo Glue scripts updated successfully!
echo ========================================
pause
