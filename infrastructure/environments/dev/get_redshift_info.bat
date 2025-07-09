@echo off
echo ========================================
echo Getting Redshift Connection Information
echo ========================================

echo Getting Redshift cluster endpoint...
terraform output redshift_cluster_endpoint

echo.
echo Getting all outputs...
terraform output

echo.
echo ========================================
echo Connection Details:
echo ========================================
echo Host: [See endpoint above]
echo Port: 5439
echo Database: ecommerce_dwh_dev
echo Username: dwh_admin
echo Password: DwhSecure123!
echo ========================================
pause
