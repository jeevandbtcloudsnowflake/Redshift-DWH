@echo off
REM E-Commerce Data Warehouse Infrastructure Deployment Script for Windows
REM This script deploys the complete AWS infrastructure using Terraform

echo ========================================
echo E-Commerce Data Warehouse Deployment
echo ========================================
echo.

REM Set environment
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=dev

echo Environment: %ENVIRONMENT%
echo Region: ap-south-1
echo.

REM Check if terraform.tfvars exists
if not exist "infrastructure\environments\%ENVIRONMENT%\terraform.tfvars" (
    echo Creating terraform.tfvars file...
    echo redshift_master_password = "DwhSecure123!" > infrastructure\environments\%ENVIRONMENT%\terraform.tfvars
    echo terraform.tfvars created successfully
    echo.
)

REM Navigate to environment directory
echo Navigating to %ENVIRONMENT% environment directory...
cd infrastructure\environments\%ENVIRONMENT%

REM Initialize Terraform
echo.
echo ========================================
echo Initializing Terraform...
echo ========================================
terraform init
if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform init failed
    pause
    exit /b 1
)

REM Validate configuration
echo.
echo ========================================
echo Validating Terraform configuration...
echo ========================================
terraform validate
if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform validation failed
    pause
    exit /b 1
)

REM Plan deployment
echo.
echo ========================================
echo Creating deployment plan...
echo ========================================
terraform plan -out=tfplan
if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform plan failed
    pause
    exit /b 1
)

REM Ask for confirmation
echo.
echo ========================================
echo DEPLOYMENT CONFIRMATION
echo ========================================
echo This will deploy AWS infrastructure which may incur costs.
echo Environment: %ENVIRONMENT%
echo Region: ap-south-1
echo.
set /p CONFIRM=Do you want to proceed with deployment? (y/N): 

if /i not "%CONFIRM%"=="y" (
    echo Deployment cancelled by user
    del tfplan 2>nul
    pause
    exit /b 0
)

REM Apply changes
echo.
echo ========================================
echo Applying Terraform configuration...
echo ========================================
terraform apply tfplan
if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform apply failed
    pause
    exit /b 1
)

REM Clean up plan file
del tfplan 2>nul

REM Show outputs
echo.
echo ========================================
echo DEPLOYMENT COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo Infrastructure outputs:
terraform output

echo.
echo ========================================
echo NEXT STEPS
echo ========================================
echo 1. Generate sample data: python scripts\utilities\generate_data.py --environment %ENVIRONMENT%
echo 2. Upload data to S3 to trigger ETL pipeline
echo 3. Monitor pipeline execution in AWS console
echo.
echo Deployment completed successfully!
pause
