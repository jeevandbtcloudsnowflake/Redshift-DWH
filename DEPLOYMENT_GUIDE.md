# 🚀 E-Commerce Data Warehouse Deployment Guide

This guide will walk you through deploying the complete e-commerce data warehouse infrastructure and running the ETL pipeline in AWS ap-south-1 region.

## 📋 Prerequisites

### Required Tools
- **AWS CLI** (v2.0+) - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **Terraform** (v1.0+) - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **Python** (3.9+) with pip
- **Git** for version control
- **jq** for JSON processing (optional but recommended)

### AWS Requirements
- **AWS Account** with appropriate permissions
- **IAM User/Role** with the following permissions:
  - EC2, VPC, S3, Redshift, Glue, Lambda, Step Functions, CloudWatch, SNS, IAM
- **AWS CLI configured** for ap-south-1 region

## 🔧 Step 1: Environment Setup

### 1.1 Clone and Setup Project
```bash
# Navigate to project directory
cd e:\Jeevan\Redshift-DWH

# Install Python dependencies
pip install -r requirements.txt

# Make deployment scripts executable (if on Linux/Mac)
chmod +x scripts/deployment/*.sh
```

### 1.2 Configure AWS CLI
```bash
# Configure AWS CLI for ap-south-1 region
aws configure

# Verify configuration
aws sts get-caller-identity
aws configure get region  # Should show: ap-south-1
```

### 1.3 Validate Environment
```bash
# Run environment validation
python scripts/deployment/validate_environment.py

# If validation fails, fix the issues before proceeding
```

## 🏗️ Step 2: Infrastructure Deployment

### 2.1 Deploy Development Environment
```bash
# Deploy infrastructure (this will take 10-15 minutes)
./scripts/deployment/deploy_infrastructure.sh dev

# Or on Windows:
bash scripts/deployment/deploy_infrastructure.sh dev
```

**What this does:**
- Creates VPC with public/private subnets
- Deploys Redshift cluster (single node for dev)
- Sets up S3 buckets with proper policies
- Creates Glue catalog and jobs
- Configures IAM roles and security groups
- Sets up CloudWatch monitoring

### 2.2 Verify Deployment
```bash
# Check Terraform outputs
cd infrastructure/environments/dev
terraform output

# Verify AWS resources
aws redshift describe-clusters --region ap-south-1
aws s3 ls | grep ecommerce-dwh
aws glue get-databases --region ap-south-1
```

### 2.3 Expected Outputs
After successful deployment, you should see:
```
vpc_id = "vpc-xxxxxxxxx"
redshift_cluster_endpoint = "ecommerce-dwh-dev-cluster.xxxxxxxxx.ap-south-1.redshift.amazonaws.com:5439"
s3_raw_data_bucket = "ecommerce-dwh-dev-raw-data-xxxxxxxx"
s3_processed_data_bucket = "ecommerce-dwh-dev-processed-data-xxxxxxxx"
s3_scripts_bucket = "ecommerce-dwh-dev-scripts-xxxxxxxx"
glue_catalog_database_name = "ecommerce_catalog_dev"
```

## 📊 Step 3: Sample Data Generation

### 3.1 Generate Development Data
```bash
# Generate sample data for development environment
python scripts/utilities/generate_data.py --environment dev

# This creates:
# - 1,000 customers
# - 500 products  
# - 5,000 orders
# - 15,000 order items
# - 50,000 web events
```

### 3.2 Verify Generated Data
```bash
# Check generated files
ls -la data/sample_data/

# Expected files:
# customers.csv, products.csv, orders.csv, order_items.csv, web_events.csv
```

### 3.3 Upload Data to S3
```bash
# Get bucket name from Terraform output
RAW_BUCKET=$(cd infrastructure/environments/dev && terraform output -raw s3_raw_data_bucket)

# Upload sample data
aws s3 cp data/sample_data/ s3://$RAW_BUCKET/data/ --recursive --region ap-south-1

# Verify upload
aws s3 ls s3://$RAW_BUCKET/data/ --recursive --region ap-south-1
```

## 🔄 Step 4: ETL Pipeline Execution

### 4.1 Deploy ETL Components

#### Upload Glue Scripts
```bash
# Get scripts bucket name
SCRIPTS_BUCKET=$(cd infrastructure/environments/dev && terraform output -raw s3_scripts_bucket)

# Upload Glue ETL scripts
aws s3 cp etl/glue_jobs/ s3://$SCRIPTS_BUCKET/glue_jobs/ --recursive --region ap-south-1

# Upload Lambda function code
cd etl/lambda_functions
zip -r data_validation.zip data_validation.py
aws s3 cp data_validation.zip s3://$SCRIPTS_BUCKET/lambda/ --region ap-south-1
cd ../..
```

#### Create Glue Jobs
```bash
# Create data processing job
aws glue create-job \
  --name "ecommerce-dwh-dev-data-processing" \
  --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ecommerce-dwh-dev-glue-service-role" \
  --command '{"Name":"glueetl","ScriptLocation":"s3://'$SCRIPTS_BUCKET'/glue_jobs/data_processing.py","PythonVersion":"3"}' \
  --default-arguments '{"--job-language":"python","--job-bookmark-option":"job-bookmark-enable","--enable-metrics":"true"}' \
  --max-capacity 2 \
  --region ap-south-1

# Create data quality job
aws glue create-job \
  --name "ecommerce-dwh-dev-data-quality" \
  --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ecommerce-dwh-dev-glue-service-role" \
  --command '{"Name":"glueetl","ScriptLocation":"s3://'$SCRIPTS_BUCKET'/glue_jobs/data_quality.py","PythonVersion":"3"}' \
  --default-arguments '{"--job-language":"python","--job-bookmark-option":"job-bookmark-enable","--enable-metrics":"true"}' \
  --max-capacity 1 \
  --region ap-south-1
```

#### Deploy Lambda Function
```bash
# Create Lambda function
aws lambda create-function \
  --function-name "ecommerce-dwh-dev-data-validation" \
  --runtime python3.9 \
  --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ecommerce-dwh-dev-lambda-execution-role" \
  --handler data_validation.lambda_handler \
  --zip-file fileb://etl/lambda_functions/data_validation.zip \
  --timeout 300 \
  --memory-size 512 \
  --region ap-south-1
```

### 4.2 Create Database Schema

#### Connect to Redshift
```bash
# Get Redshift endpoint
REDSHIFT_ENDPOINT=$(cd infrastructure/environments/dev && terraform output -raw redshift_cluster_endpoint)

# Connect using psql (if installed) or use AWS Query Editor
# psql -h $REDSHIFT_ENDPOINT -U dwh_admin -d ecommerce_dwh_dev -p 5439
```

#### Create Tables
```sql
-- Run these SQL scripts in Redshift Query Editor or psql:

-- 1. Create staging tables
\i sql/ddl/create_staging_tables.sql

-- 2. Create dimension tables  
\i sql/ddl/create_dimension_tables.sql

-- 3. Create fact tables
\i sql/ddl/create_fact_tables.sql
```

### 4.3 Run ETL Pipeline

#### Manual Execution
```bash
# Start Glue crawlers to catalog raw data
aws glue start-crawler --name "ecommerce-dwh-dev-raw-data-crawler" --region ap-south-1

# Wait for crawler to complete (check status)
aws glue get-crawler --name "ecommerce-dwh-dev-raw-data-crawler" --region ap-south-1

# Run data processing job
aws glue start-job-run \
  --job-name "ecommerce-dwh-dev-data-processing" \
  --arguments '{"--raw_data_bucket":"'$RAW_BUCKET'","--processed_data_bucket":"'$(cd infrastructure/environments/dev && terraform output -raw s3_processed_data_bucket)'","--database_name":"ecommerce_catalog_dev"}' \
  --region ap-south-1

# Monitor job execution
aws glue get-job-runs --job-name "ecommerce-dwh-dev-data-processing" --region ap-south-1
```

## 🔍 Step 5: Validation and Testing

### 5.1 Verify Data in Redshift
```sql
-- Connect to Redshift and run these queries:

-- Check staging tables
SELECT 'customers' as table_name, COUNT(*) as row_count FROM staging.stg_customers
UNION ALL
SELECT 'products', COUNT(*) FROM staging.stg_products  
UNION ALL
SELECT 'orders', COUNT(*) FROM staging.stg_orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM staging.stg_order_items;

-- Check dimension tables
SELECT 'dim_customer' as table_name, COUNT(*) as row_count FROM dimensions.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dimensions.dim_product
UNION ALL  
SELECT 'dim_date', COUNT(*) FROM dimensions.dim_date;

-- Sample analytics query
SELECT 
    dc.customer_segment,
    COUNT(DISTINCT fs.order_id) as total_orders,
    SUM(fs.order_total_amount) as total_revenue
FROM facts.fact_sales fs
JOIN dimensions.dim_customer dc ON fs.customer_key = dc.customer_key
WHERE dc.is_current = true
GROUP BY dc.customer_segment
ORDER BY total_revenue DESC;
```

### 5.2 Monitor Pipeline Health
```bash
# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws-glue/jobs" --region ap-south-1

# Check Lambda function logs  
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/ecommerce-dwh" --region ap-south-1

# View CloudWatch dashboard
echo "Visit: https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:"
```

## 🎯 Step 6: Next Steps

### 6.1 Set Up Automated Pipeline
- Configure S3 event notifications to trigger Lambda
- Set up Step Functions for workflow orchestration
- Schedule regular data loads

### 6.2 Connect BI Tools
- Configure QuickSight or Tableau
- Create business dashboards
- Set up automated reports

### 6.3 Production Deployment
```bash
# Deploy to staging/production
./scripts/deployment/deploy_infrastructure.sh staging
./scripts/deployment/deploy_infrastructure.sh prod
```

## 🚨 Troubleshooting

### Common Issues

1. **Terraform Permission Errors**
   ```bash
   # Check IAM permissions
   aws iam get-user
   aws iam list-attached-user-policies --user-name YOUR_USERNAME
   ```

2. **Redshift Connection Issues**
   ```bash
   # Check security groups and VPC settings
   aws ec2 describe-security-groups --region ap-south-1
   ```

3. **Glue Job Failures**
   ```bash
   # Check Glue job logs
   aws glue get-job-runs --job-name JOB_NAME --region ap-south-1
   ```

### Getting Help
- Check AWS CloudWatch logs for detailed error messages
- Review Terraform state: `terraform show`
- Validate AWS service quotas and limits
- Ensure all prerequisites are met

## 💰 Cost Management

### Development Environment Costs (Estimated)
- **Redshift**: ~$0.25/hour (single dc2.large node)
- **S3**: ~$0.023/GB/month
- **Glue**: ~$0.44/DPU-hour
- **Lambda**: ~$0.0000002/request
- **Data Transfer**: Minimal within same region

### Cost Optimization
- Dev environment auto-pauses Redshift during non-business hours
- S3 lifecycle policies move old data to cheaper storage classes
- Monitor usage with AWS Cost Explorer

---

**🎉 Congratulations! You now have a fully functional e-commerce data warehouse running in AWS ap-south-1 region.**
