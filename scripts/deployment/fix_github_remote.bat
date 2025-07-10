@echo off
echo ========================================
echo Fix GitHub Remote Configuration
echo ========================================

echo Current remote configuration:
git remote -v

echo.
echo Removing incorrect remote...
git remote remove origin 2>nul

echo.
set /p GITHUB_USERNAME="Enter your GitHub username: "

if "%GITHUB_USERNAME%"=="" (
    echo ERROR: GitHub username cannot be empty.
    pause
    exit /b 1
)

echo.
echo Adding correct remote URL...
git remote add origin https://github.com/%GITHUB_USERNAME%/Redshift-DWH.git

echo.
echo New remote configuration:
git remote -v

echo.
echo ========================================
echo IMPORTANT: Create Repository on GitHub
echo ========================================
echo.
echo Before pushing, you MUST create the repository on GitHub:
echo.
echo 1. Go to: https://github.com/new
echo 2. Repository name: Redshift-DWH
echo 3. Description: Enterprise E-commerce Data Warehouse on AWS
echo 4. Visibility: Private (recommended)
echo 5. Initialize: Do NOT check any boxes
echo 6. Click "Create repository"
echo.
echo Repository URL will be:
echo https://github.com/%GITHUB_USERNAME%/Redshift-DWH
echo.

set /p CREATED="Have you created the repository on GitHub? (y/N): "
if /i not "%CREATED%"=="y" (
    echo Please create the repository first, then run this script again.
    pause
    exit /b 0
)

echo.
echo Setting default branch to main...
git branch -M main

echo.
echo Pushing to GitHub...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Repository pushed to GitHub
    echo ========================================
    echo.
    echo Your repository is now available at:
    echo https://github.com/%GITHUB_USERNAME%/Redshift-DWH
    echo.
) else (
    echo.
    echo ========================================
    echo Push failed - Authentication needed
    echo ========================================
    echo.
    echo You may need to set up authentication:
    echo.
    echo Option 1: Personal Access Token
    echo 1. Go to: https://github.com/settings/tokens
    echo 2. Generate new token with 'repo' scope
    echo 3. Use token as password when prompted
    echo.
    echo Option 2: GitHub CLI
    echo 1. Install GitHub CLI: https://cli.github.com/
    echo 2. Run: gh auth login
    echo 3. Try push again: git push -u origin main
    echo.
)

pause
