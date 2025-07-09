@echo off
echo ========================================
echo Setting up Git Repository
echo ========================================

echo Initializing Git repository...
git init

echo.
echo Setting up Git configuration (update with your details)...
git config user.name "Your Name"
git config user.email "your.email@example.com"

echo.
echo Adding all files to Git...
git add .

echo.
echo Creating initial commit...
git commit -m "Initial commit: Complete e-commerce data warehouse implementation

- AWS infrastructure with Terraform (VPC, Redshift, Glue, S3, IAM)
- ETL pipeline with data processing and quality validation
- Star schema data model with fact and dimension tables
- Sample e-commerce data (customers, products, orders)
- Business intelligence analytics queries
- Monitoring and alerting setup
- Comprehensive documentation"

echo.
echo Checking Git status...
git status

echo.
echo ========================================
echo Git repository setup completed!
echo ========================================
echo.
echo Next steps:
echo 1. Update git config with your name and email:
echo    git config user.name "Your Name"
echo    git config user.email "your.email@example.com"
echo.
echo 2. Create a remote repository on GitHub/GitLab/etc.
echo.
echo 3. Add remote origin:
echo    git remote add origin https://github.com/yourusername/redshift-dwh.git
echo.
echo 4. Push to remote:
echo    git push -u origin main
echo.
pause
