@echo off
echo ========================================
echo Running Data Quality Job
echo ========================================

REM Replace with your actual bucket name
set PROCESSED_BUCKET=ecommerce-dwh-dev-dev-processed-data-bb8ygosl

echo Processed data bucket: %PROCESSED_BUCKET%
echo.

echo Starting data quality job...
aws glue start-job-run --job-name ecommerce-dwh-dev-data-quality --arguments "{\"--processed_data_bucket\":\"%PROCESSED_BUCKET%\",\"--database_name\":\"ecommerce_catalog_dev\"}" --region ap-south-1

echo.
echo Checking job status...
aws glue get-job-runs --job-name ecommerce-dwh-dev-data-quality --max-items 1 --region ap-south-1

echo.
echo ========================================
echo Data quality job started!
echo ========================================
echo.
echo Monitor the job in AWS Console:
echo AWS Glue ^> Jobs ^> ecommerce-dwh-dev-data-quality
echo.
pause
