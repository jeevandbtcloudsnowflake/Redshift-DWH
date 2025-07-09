@echo off
echo ========================================
echo Uploading Sample Data to S3
echo ========================================

REM You need to replace this with your actual raw data bucket name
REM Get it from: AWS Console -> S3 -> look for ecommerce-dwh-dev-raw-data-xxxxxxxx
set RAW_BUCKET=ecommerce-dwh-dev-raw-data-xxxxxxxx

echo Raw data bucket: %RAW_BUCKET%
echo.

echo Uploading sample data files...
aws s3 cp data\sample_data\customers.csv s3://%RAW_BUCKET%/data/customers.csv --region ap-south-1
aws s3 cp data\sample_data\products.csv s3://%RAW_BUCKET%/data/products.csv --region ap-south-1
aws s3 cp data\sample_data\orders.csv s3://%RAW_BUCKET%/data/orders.csv --region ap-south-1
aws s3 cp data\sample_data\order_items.csv s3://%RAW_BUCKET%/data/order_items.csv --region ap-south-1

echo.
echo Verifying uploads...
aws s3 ls s3://%RAW_BUCKET%/data/ --region ap-south-1

echo.
echo ========================================
echo Sample data upload completed!
echo ========================================
echo.
echo Next steps:
echo 1. Run Glue crawlers to catalog the data
echo 2. Execute ETL jobs
echo 3. Verify data in Redshift
echo.
pause
