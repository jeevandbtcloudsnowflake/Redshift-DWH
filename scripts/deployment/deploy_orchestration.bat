@echo off
echo ========================================
echo Deploying ETL Orchestration
echo AWS Glue Workflows + Step Functions
echo ========================================

set ENVIRONMENT=dev
set REGION=ap-south-1

echo Environment: %ENVIRONMENT%
echo Region: %REGION%
echo.

echo What will be deployed:
echo =====================
echo.
echo 1. AWS Glue Workflows:
echo    - ETL workflow with triggers
echo    - Scheduled execution (daily at 2 AM UTC)
echo    - Automatic crawler → processing → quality chain
echo.
echo 2. AWS Step Functions:
echo    - Advanced state machine with error handling
echo    - Scheduled execution (daily at 3 AM UTC)
echo    - SNS notifications for success/failure
echo    - Retry logic and conditional branching
echo.
echo 3. CloudWatch Integration:
echo    - Event rules for scheduling
echo    - Monitoring and logging
echo    - Dashboard updates
echo.

set /p CONTINUE="Do you want to proceed with deployment? (y/N): "
if /i not "%CONTINUE%"=="y" (
    echo Deployment cancelled.
    pause
    exit /b 0
)

echo.
echo Step 1: Validate Terraform Configuration
echo ========================================
cd infrastructure\environments\%ENVIRONMENT%

echo Checking Terraform format...
terraform fmt -check -recursive ..\..\

echo Validating Terraform configuration...
terraform validate

if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform validation failed!
    cd ..\..\..
    pause
    exit /b 1
)

echo ✓ Terraform configuration is valid

echo.
echo Step 2: Plan Orchestration Deployment
echo =====================================
echo Planning Terraform changes...
terraform plan -out=orchestration.tfplan

echo.
echo Step 3: Review and Apply Changes
echo ================================
set /p APPLY="Apply the planned changes? (y/N): "
if /i not "%APPLY%"=="y" (
    echo Deployment cancelled.
    del orchestration.tfplan
    cd ..\..\..
    pause
    exit /b 0
)

echo Applying Terraform changes...
terraform apply orchestration.tfplan

if %ERRORLEVEL% neq 0 (
    echo ERROR: Terraform apply failed!
    cd ..\..\..
    pause
    exit /b 1
)

echo.
echo Step 4: Extract Deployment Information
echo =====================================
echo Getting Terraform outputs...

echo.
echo Glue Workflow Information:
echo -------------------------
for /f "tokens=2 delims= " %%i in ('terraform output -raw glue_etl_workflow_name 2^>nul') do set GLUE_WORKFLOW=%%i
for /f "tokens=2 delims= " %%i in ('terraform output -raw glue_etl_schedule_rule_name 2^>nul') do set GLUE_SCHEDULE=%%i

echo Workflow Name: %GLUE_WORKFLOW%
echo Schedule Rule: %GLUE_SCHEDULE%

echo.
echo Step Functions Information:
echo --------------------------
for /f "tokens=2 delims= " %%i in ('terraform output -raw step_functions_state_machine_name 2^>nul') do set SF_STATE_MACHINE=%%i
for /f "tokens=2 delims= " %%i in ('terraform output -raw step_functions_schedule_rule_name 2^>nul') do set SF_SCHEDULE=%%i

echo State Machine: %SF_STATE_MACHINE%
echo Schedule Rule: %SF_SCHEDULE%

cd ..\..\..

echo.
echo Step 5: Verify Deployment
echo =========================

echo Checking Glue Workflow...
aws glue get-workflow --name %GLUE_WORKFLOW% --region %REGION% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ✓ Glue Workflow deployed successfully
) else (
    echo ✗ Glue Workflow deployment failed
)

echo Checking Step Functions State Machine...
aws stepfunctions describe-state-machine --state-machine-arn "arn:aws:states:%REGION%:*:stateMachine:%SF_STATE_MACHINE%" --region %REGION% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ✓ Step Functions State Machine deployed successfully
) else (
    echo ✗ Step Functions deployment failed
)

echo.
echo ========================================
echo ETL Orchestration Deployment Complete!
echo ========================================
echo.
echo 🔄 GLUE WORKFLOWS (Simple Orchestration)
echo ----------------------------------------
echo Schedule: Daily at 2:00 AM UTC
echo Workflow: %GLUE_WORKFLOW%
echo.
echo Manual execution:
echo aws glue start-workflow-run --name %GLUE_WORKFLOW% --region %REGION%
echo.
echo Check status:
echo aws glue get-workflow-runs --name %GLUE_WORKFLOW% --region %REGION%
echo.
echo.
echo 🚀 STEP FUNCTIONS (Advanced Orchestration)
echo ------------------------------------------
echo Schedule: Daily at 3:00 AM UTC
echo State Machine: %SF_STATE_MACHINE%
echo.
echo Manual execution:
echo aws stepfunctions start-execution --state-machine-arn "arn:aws:states:%REGION%:ACCOUNT_ID:stateMachine:%SF_STATE_MACHINE%" --region %REGION%
echo.
echo Check status:
echo aws stepfunctions list-executions --state-machine-arn "arn:aws:states:%REGION%:ACCOUNT_ID:stateMachine:%SF_STATE_MACHINE%" --region %REGION%
echo.
echo.
echo 📊 MONITORING
echo -------------
echo CloudWatch Dashboards: https://console.aws.amazon.com/cloudwatch/home?region=%REGION%#dashboards
echo Glue Console: https://console.aws.amazon.com/glue/home?region=%REGION%#etl:tab=workflows
echo Step Functions Console: https://console.aws.amazon.com/states/home?region=%REGION%#/statemachines
echo.
echo.
echo 🎯 NEXT STEPS
echo -------------
echo 1. Test both orchestration methods manually
echo 2. Monitor the first scheduled runs
echo 3. Check CloudWatch logs for any issues
echo 4. Choose your preferred orchestration method
echo 5. Disable the unused method if desired
echo.
echo.
echo 📋 ORCHESTRATION COMPARISON
echo ---------------------------
echo Glue Workflows:
echo ✓ Native AWS Glue integration
echo ✓ Visual workflow designer
echo ✓ Simple setup and maintenance
echo ✓ Built-in retry mechanisms
echo.
echo Step Functions:
echo ✓ Advanced error handling
echo ✓ Complex conditional logic
echo ✓ SNS notifications
echo ✓ Visual state machine designer
echo ✓ Integration with multiple AWS services
echo.
pause
