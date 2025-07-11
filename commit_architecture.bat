@echo off
echo Adding architecture files...
git add docs/architecture/
git add scripts/utilities/generate_architecture_pdf.py

echo Committing changes...
git commit -m "Add professional AWS architecture diagrams with actual service icons and PDF generation"

echo Pushing to GitHub...
git push origin main

echo Done!
echo.
echo Architecture diagrams are now available:
echo 1. HTML Interactive: docs/architecture/AWS_ARCHITECTURE_HTML.html
echo 2. PDF Document: docs/architecture/diagrams/AWS_Architecture_Simple.pdf
echo 3. Python Generator: docs/architecture/AWS_ARCHITECTURE_DIAGRAM.py
echo 4. Complete Documentation: docs/architecture/README.md
echo.
pause
