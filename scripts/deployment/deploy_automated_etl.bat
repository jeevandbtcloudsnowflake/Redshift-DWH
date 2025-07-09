@echo off
echo ========================================
echo Deploying Automated ETL Pipeline
echo ========================================

set ENVIRONMENT=dev
set REGION=ap-south-1

echo.
echo Step 1: Deploy Glue Workflow Infrastructure
echo -------------------------------------------
echo Updating Terraform to include Glue Workflows...

cd infrastructure\environments\%ENVIRONMENT%

echo Running terraform plan...
terraform plan -out=tfplan

echo.
set /p CONTINUE="Do you want to apply these changes? (y/N): "
if /i "%CONTINUE%"=="y" (
    echo Applying Terraform changes...
    terraform apply tfplan
    echo Terraform deployment completed!
) else (
    echo Skipping Terraform deployment.
)

cd ..\..\..

echo.
echo Step 2: Test ETL Pipeline Script
echo --------------------------------
echo Testing the automated ETL pipeline script...

python scripts\automation\run_etl_pipeline.py --environment %ENVIRONMENT% --skip-crawler

echo.
echo Step 3: Setup Options
echo ---------------------
echo Choose your automation method:
echo.
echo 1. AWS Glue Workflows (Recommended)
echo 2. GitHub Actions (CI/CD)
echo 3. Local Cron Job (Linux/Mac)
echo 4. Windows Task Scheduler
echo 5. Manual execution only
echo.

set /p CHOICE="Enter your choice (1-5): "

if "%CHOICE%"=="1" goto GLUE_WORKFLOW
if "%CHOICE%"=="2" goto GITHUB_ACTIONS
if "%CHOICE%"=="3" goto CRON_JOB
if "%CHOICE%"=="4" goto TASK_SCHEDULER
if "%CHOICE%"=="5" goto MANUAL_ONLY

:GLUE_WORKFLOW
echo.
echo Setting up AWS Glue Workflows...
echo.
echo The Glue Workflow has been deployed with Terraform.
echo.
echo To start the workflow manually:
aws glue start-workflow-run --name ecommerce-dwh-%ENVIRONMENT%-etl-workflow --region %REGION%
echo.
echo To check workflow status:
aws glue get-workflow-run --name ecommerce-dwh-%ENVIRONMENT%-etl-workflow --run-id RUN_ID --region %REGION%
echo.
echo The workflow is scheduled to run daily at 2 AM UTC.
echo You can modify the schedule in the CloudWatch Events console.
goto END

:GITHUB_ACTIONS
echo.
echo Setting up GitHub Actions...
echo.
echo 1. Push your code to GitHub
echo 2. Add these secrets to your GitHub repository:
echo    - AWS_ACCESS_KEY_ID
echo    - AWS_SECRET_ACCESS_KEY
echo.
echo 3. The workflow will run automatically:
echo    - Daily at 2 AM UTC (Monday-Friday)
echo    - Weekly full pipeline on Sunday at 3 AM UTC
echo    - Manual trigger available in GitHub Actions tab
echo.
echo GitHub Actions workflow file: .github/workflows/etl-pipeline.yml
goto END

:CRON_JOB
echo.
echo Setting up Cron Job (Linux/Mac only)...
echo.
echo Run this command on your Linux/Mac server:
echo bash scripts/automation/setup_cron_scheduler.sh
echo.
echo This will:
echo - Create a daily cron job at 2 AM
echo - Set up logging
echo - Create wrapper scripts
goto END

:TASK_SCHEDULER
echo.
echo Setting up Windows Task Scheduler...
echo.
echo 1. Open Task Scheduler (taskschd.msc)
echo 2. Create Basic Task
echo 3. Set trigger: Daily at 2:00 AM
echo 4. Set action: Start a program
echo 5. Program: python
echo 6. Arguments: scripts\automation\run_etl_pipeline.py --environment %ENVIRONMENT%
echo 7. Start in: %CD%
echo.
echo Or run this PowerShell command as Administrator:
echo $action = New-ScheduledTaskAction -Execute "python" -Argument "scripts\automation\run_etl_pipeline.py --environment %ENVIRONMENT%" -WorkingDirectory "%CD%"
echo $trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
echo Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "ETL Pipeline" -Description "Daily ETL Pipeline"
goto END

:MANUAL_ONLY
echo.
echo Manual Execution Setup
echo ----------------------
echo.
echo To run the ETL pipeline manually:
echo python scripts\automation\run_etl_pipeline.py --environment %ENVIRONMENT%
echo.
echo To run without crawler:
echo python scripts\automation\run_etl_pipeline.py --environment %ENVIRONMENT% --skip-crawler
echo.
echo To run individual components:
echo aws glue start-crawler --name ecommerce-dwh-%ENVIRONMENT%-raw-data-crawler --region %REGION%
echo aws glue start-job-run --job-name ecommerce-dwh-%ENVIRONMENT%-data-processing --region %REGION%
echo aws glue start-job-run --job-name ecommerce-dwh-%ENVIRONMENT%-data-quality --region %REGION%
goto END

:END
echo.
echo ========================================
echo Automated ETL Setup Completed!
echo ========================================
echo.
echo Summary:
echo - Environment: %ENVIRONMENT%
echo - Region: %REGION%
echo - ETL Script: scripts\automation\run_etl_pipeline.py
echo.
echo Monitoring:
echo - CloudWatch Logs: /aws/glue/jobs/
echo - CloudWatch Dashboards: ecommerce-dwh-%ENVIRONMENT%-dashboard
echo - S3 Quality Reports: ecommerce-dwh-%ENVIRONMENT%-processed-data/quality_reports/
echo.
echo Next Steps:
echo 1. Test the automation
echo 2. Monitor the first few runs
echo 3. Set up alerting if needed
echo 4. Document the process for your team
echo.
pause
