#!/bin/bash

# Setup Cron Scheduler for ETL Pipeline
# This script sets up a cron job to run the ETL pipeline automatically

set -e

# Configuration
PROJECT_DIR="/path/to/Redshift-DWH"  # Update this path
ENVIRONMENT="dev"
LOG_DIR="$PROJECT_DIR/logs"
PYTHON_PATH="/usr/bin/python3"  # Update if needed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up ETL Pipeline Cron Scheduler${NC}"
echo "========================================"

# Create logs directory
echo "Creating logs directory..."
mkdir -p "$LOG_DIR"

# Create wrapper script
WRAPPER_SCRIPT="$PROJECT_DIR/scripts/automation/etl_cron_wrapper.sh"
echo "Creating wrapper script: $WRAPPER_SCRIPT"

cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash

# ETL Pipeline Cron Wrapper Script
# This script is called by cron to run the ETL pipeline

# Set environment variables
export AWS_DEFAULT_REGION=ap-south-1
export PATH=/usr/local/bin:/usr/bin:/bin

# Change to project directory
cd "$PROJECT_DIR"

# Log file with timestamp
LOG_FILE="$LOG_DIR/etl_pipeline_\$(date +%Y%m%d_%H%M%S).log"

# Run the ETL pipeline
echo "Starting ETL pipeline at \$(date)" >> "\$LOG_FILE"
$PYTHON_PATH scripts/automation/run_etl_pipeline.py --environment $ENVIRONMENT >> "\$LOG_FILE" 2>&1

# Log completion
echo "ETL pipeline finished at \$(date)" >> "\$LOG_FILE"

# Keep only last 30 log files
find "$LOG_DIR" -name "etl_pipeline_*.log" -type f -mtime +30 -delete

# Optional: Send email notification (uncomment if needed)
# if [ \$? -eq 0 ]; then
#     echo "ETL pipeline completed successfully" | mail -s "ETL Success" admin@company.com
# else
#     echo "ETL pipeline failed. Check logs at \$LOG_FILE" | mail -s "ETL Failure" admin@company.com
# fi
EOF

# Make wrapper script executable
chmod +x "$WRAPPER_SCRIPT"

# Create cron job
CRON_JOB="0 2 * * * $WRAPPER_SCRIPT"

echo -e "${YELLOW}Setting up cron job:${NC}"
echo "$CRON_JOB"

# Add to crontab
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo -e "${GREEN}Cron scheduler setup completed!${NC}"
echo ""
echo "Schedule: Daily at 2:00 AM"
echo "Logs: $LOG_DIR"
echo "Wrapper script: $WRAPPER_SCRIPT"
echo ""
echo "To view current cron jobs:"
echo "  crontab -l"
echo ""
echo "To remove the cron job:"
echo "  crontab -e"
echo ""
echo "To test the pipeline manually:"
echo "  $PYTHON_PATH $PROJECT_DIR/scripts/automation/run_etl_pipeline.py --environment $ENVIRONMENT"
