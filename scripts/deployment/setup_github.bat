@echo off
echo ========================================
echo Setting up GitHub Remote Repository
echo ========================================

echo.
echo STEP 1: Create GitHub Repository
echo --------------------------------
echo 1. Go to https://github.com/new
echo 2. Repository name: ecommerce-data-warehouse
echo 3. Description: Production-ready e-commerce data warehouse on AWS
echo 4. Set to PRIVATE (recommended for enterprise projects)
echo 5. Do NOT initialize with README, .gitignore, or license
echo 6. Click "Create repository"
echo.

set /p GITHUB_USERNAME="Enter your GitHub username: "
set /p REPO_NAME="Enter repository name (default: ecommerce-data-warehouse): "

if "%REPO_NAME%"=="" set REPO_NAME=ecommerce-data-warehouse

echo.
echo STEP 2: Configure Git User
echo --------------------------
set /p GIT_NAME="Enter your full name for Git: "
set /p GIT_EMAIL="Enter your email for Git: "

git config user.name "%GIT_NAME%"
git config user.email "%GIT_EMAIL%"

echo.
echo STEP 3: Add Remote Origin
echo -------------------------
git remote add origin https://github.com/%GITHUB_USERNAME%/%REPO_NAME%.git

echo.
echo STEP 4: Rename Branch to Main
echo -----------------------------
git branch -M main

echo.
echo STEP 5: Push to GitHub
echo ----------------------
echo Pushing to GitHub...
git push -u origin main

echo.
echo ========================================
echo GitHub Setup Completed!
echo ========================================
echo.
echo Repository URL: https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
echo.
echo Next steps:
echo 1. Visit your repository on GitHub
echo 2. Add repository description and topics
echo 3. Set up branch protection rules
echo 4. Add collaborators if needed
echo.
pause
