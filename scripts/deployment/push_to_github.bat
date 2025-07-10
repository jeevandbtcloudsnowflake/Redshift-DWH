@echo off
echo ========================================
echo Push to GitHub Repository
echo ========================================

echo.
echo This script will push your local repository to GitHub.
echo.

REM Check if Git is installed
where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git is not installed or not in PATH.
    echo Please install Git from https://git-scm.com/downloads
    pause
    exit /b 1
)

REM Check if we're in a Git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Not in a Git repository.
    echo Please run this script from the root of your Git repository.
    pause
    exit /b 1
)

REM Check for uncommitted changes
git diff-index --quiet HEAD -- || (
    echo WARNING: You have uncommitted changes.
    echo.
    git status
    echo.
    set /p CONTINUE="Do you want to commit these changes before pushing? (y/N): "
    if /i "%CONTINUE%"=="y" (
        set /p COMMIT_MSG="Enter commit message: "
        git add .
        git commit -m "%COMMIT_MSG%"
    )
)

REM Check if remote exists
git remote -v | findstr "origin" >nul
if %ERRORLEVEL% NEQ 0 (
    echo No remote repository configured.
    echo.
    set /p GITHUB_USERNAME="Enter your GitHub username: "
    set /p REPO_NAME="Enter repository name (default: Redshift-DWH): "
    
    if "%REPO_NAME%"=="" set REPO_NAME=Redshift-DWH
    
    echo.
    echo Setting up remote repository...
    git remote add origin https://github.com/%GITHUB_USERNAME%/%REPO_NAME%.git
    
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to add remote repository.
        pause
        exit /b 1
    )
    
    echo Remote repository added successfully.
) else (
    echo Remote repository already configured.
    git remote -v
)

echo.
echo Step 1: Create GitHub Repository
echo -------------------------------
echo 1. Go to https://github.com/new
echo 2. Repository name: Redshift-DWH
echo 3. Description: Enterprise E-commerce Data Warehouse on AWS
echo 4. Set to PRIVATE (recommended for enterprise projects)
echo 5. Do NOT initialize with README, .gitignore, or license
echo 6. Click "Create repository"
echo.
echo Press any key when you've created the repository...
pause >nul

echo.
echo Step 2: Push to GitHub
echo ---------------------
echo Pushing to GitHub...
echo.

REM Set default branch name to main
git branch -M main

REM Push to GitHub
git push -u origin main

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Push failed.
    echo.
    echo Possible reasons:
    echo 1. Repository doesn't exist on GitHub
    echo 2. You don't have permission to push to this repository
    echo 3. Authentication failed
    echo.
    echo Try pushing manually with:
    echo git push -u origin main
    echo.
    echo Or set up a personal access token:
    echo 1. Go to https://github.com/settings/tokens
    echo 2. Generate a new token with 'repo' scope
    echo 3. Use the token as your password when pushing
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Push to GitHub Completed!
echo ========================================
echo.
echo Your repository is now available at:
echo https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
echo.
echo Next steps:
echo 1. Set up branch protection rules
echo 2. Add collaborators if needed
echo 3. Set up GitHub Actions for CI/CD
echo.
pause
