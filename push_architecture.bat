@echo off
echo Adding files...
git add docs/architecture/ARCHITECTURE_OVERVIEW.md
git add docs/architecture/SIMPLE_ARCHITECTURE.md
git add README.md

echo Committing...
git commit -m "Add architecture diagrams and documentation"

echo Pushing to GitHub...
git push origin main

echo Done!
pause
