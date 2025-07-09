@echo off
echo ========================================
echo Setting up Python Dependencies and Generating Sample Data
echo ========================================

echo Installing required Python packages...
pip install faker==20.1.0 pandas==2.1.4 numpy==1.24.3

echo.
echo Checking if packages are installed...
python -c "import faker, pandas, numpy; print('All packages installed successfully!')"

echo.
echo ========================================
echo Generating Sample Data for Development Environment
echo ========================================

echo Creating output directory...
if not exist "data\sample_data" mkdir data\sample_data

echo Running data generation script...
python data\generators\generate_sample_data.py

echo.
echo Checking generated files...
dir data\sample_data\*.csv

echo.
echo ========================================
echo Data Generation Completed!
echo ========================================
pause
