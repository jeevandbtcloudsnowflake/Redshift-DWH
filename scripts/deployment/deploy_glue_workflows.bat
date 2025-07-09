@echo off
echo ========================================
echo Deploying AWS Glue Workflows
echo ========================================

set ENVIRONMENT=dev
set REGION=ap-south-1

echo Environment: %ENVIRONMENT%
echo Region: %REGION%
echo.

echo Step 1: Validate Terraform Configuration
echo -----------------------------------------
cd infrastructure\environments\%ENVIRONMENT%

echo Checking Terraform format...
terraform fmt -check -recursive ..\..\

echo Validating Terraform configuration...
terraform validate

if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform validation failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Plan Glue Workflow Deployment
echo -------------------------------------
echo Planning Terraform changes...
terraform plan -out=glue-workflows.tfplan

echo.
echo Step 3: Review Changes
echo ---------------------
echo Please review the planned changes above.
echo.
echo The following resources will be created:
echo - AWS Glue Workflow for ETL orchestration
echo - CloudWatch Event Rule for scheduling (daily at 2 AM UTC)
echo - CloudWatch Event Target to trigger workflow
echo - IAM roles and policies for workflow execution
echo - Workflow triggers for crawler and jobs
echo.

set /p CONTINUE="Do you want to apply these changes? (y/N): "
if /i not "%CONTINUE%"=="y" (
    echo Deployment cancelled.
    del glue-workflows.tfplan
    cd ..\..\..
    pause
    exit /b 0
)

echo.
echo Step 4: Deploy Glue Workflows
echo -----------------------------
echo Applying Terraform changes...
terraform apply glue-workflows.tfplan

if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform apply failed!
    cd ..\..\..
    pause
    exit /b 1
)

echo.
echo Step 5: Get Deployment Outputs
echo ------------------------------
echo Getting Terraform outputs...
terraform output

echo.
echo Extracting workflow information...
for /f "tokens=2 delims= " %%i in ('terraform output -raw glue_etl_workflow_name 2^>nul') do set WORKFLOW_NAME=%%i
for /f "tokens=2 delims= " %%i in ('terraform output -raw glue_etl_schedule_rule_name 2^>nul') do set SCHEDULE_RULE=%%i

cd ..\..\..

echo.
echo Step 6: Verify Deployment
echo -------------------------
echo Checking if Glue Workflow was created...
aws glue get-workflow --name %WORKFLOW_NAME% --region %REGION% >nul 2>&1

if %ERRORLEVEL% equ 0 (
    echo ✓ Glue Workflow created successfully: %WORKFLOW_NAME%
) else (
    echo ✗ Failed to find Glue Workflow
)

echo.
echo Checking CloudWatch Event Rule...
aws events describe-rule --name %SCHEDULE_RULE% --region %REGION% >nul 2>&1

if %ERRORLEVEL% equ 0 (
    echo ✓ CloudWatch Event Rule created successfully: %SCHEDULE_RULE%
) else (
    echo ✗ Failed to find CloudWatch Event Rule
)

echo.
echo ========================================
echo Glue Workflows Deployment Completed!
echo ========================================
echo.
echo Workflow Details:
echo - Name: %WORKFLOW_NAME%
echo - Schedule: Daily at 2:00 AM UTC
echo - Schedule Rule: %SCHEDULE_RULE%
echo.
echo Manual Commands:
echo.
echo Start workflow manually:
echo aws glue start-workflow-run --name %WORKFLOW_NAME% --region %REGION%
echo.
echo Check workflow status:
echo aws glue get-workflow-runs --name %WORKFLOW_NAME% --region %REGION%
echo.
echo View workflow in AWS Console:
echo https://console.aws.amazon.com/glue/home?region=%REGION%#etl:tab=workflows
echo.
echo Next Steps:
echo 1. Test the workflow manually
echo 2. Monitor the first scheduled run
echo 3. Check CloudWatch logs for any issues
echo 4. Proceed with Step Functions deployment
echo.
pause
