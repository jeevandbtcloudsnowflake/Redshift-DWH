# ETL Pipeline Documentation

This directory contains the complete ETL (Extract, Transform, Load) pipeline for the e-commerce data warehouse project, built using AWS services including Glue, Lambda, and Step Functions.

## Architecture Overview

The ETL pipeline follows a modern, cloud-native architecture with the following components:

```
Raw Data (S3) → Data Validation (Lambda) → Data Processing (Glue) → Quality Checks (Glue) → Data Warehouse (Redshift)
                      ↓
              Step Functions Orchestration
                      ↓
              Monitoring & Alerting (CloudWatch/SNS)
```

## Directory Structure

```
etl/
├── glue_jobs/              # AWS Glue ETL job scripts
│   ├── data_processing.py      # Main data transformation job
│   └── data_quality.py         # Data quality validation job
├── lambda_functions/       # AWS Lambda function code
│   └── data_validation.py      # Real-time data validation
├── step_functions/         # AWS Step Functions workflows
│   └── etl_workflow.json       # Complete ETL orchestration
└── data_quality/          # Data quality framework
    └── data_quality_checks.py  # Comprehensive quality checks
```

## Pipeline Components

### 1. Data Validation (Lambda)

**Function**: `data_validation.py`
- **Trigger**: S3 object creation events
- **Purpose**: Validate incoming data files before processing
- **Features**:
  - Schema validation
  - Data quality checks
  - File format verification
  - Automatic ETL job triggering
  - Error notifications

**Key Validations**:
- Required column presence
- Data type validation
- Null value thresholds
- Business rule validation
- Row count validation

### 2. Data Processing (Glue)

**Job**: `data_processing.py`
- **Purpose**: Transform raw data into analytics-ready format
- **Features**:
  - Data cleansing and standardization
  - Business logic application
  - Derived field calculations
  - Data type conversions
  - Error handling and logging

**Transformations**:
- **Customers**: Full name concatenation, age calculation, email domain extraction
- **Products**: Profit margin calculation, price categorization, stock status
- **Orders**: Date parsing, shipping metrics, weekend flags
- **Order Items**: Line total validation, quantity checks

### 3. Data Quality Framework

**Module**: `data_quality_checks.py`
- **Purpose**: Comprehensive data quality validation
- **Dimensions**:
  - **Completeness**: Missing data detection
  - **Accuracy**: Business rule validation
  - **Consistency**: Cross-table relationship checks
  - **Validity**: Format and range validation

**Quality Metrics**:
- Completeness rates by column
- Accuracy percentages
- Consistency scores
- Validity measurements
- Trend analysis over time

### 4. Workflow Orchestration (Step Functions)

**Workflow**: `etl_workflow.json`
- **Purpose**: Orchestrate the complete ETL pipeline
- **Features**:
  - Error handling and retries
  - Conditional logic
  - Parallel processing
  - Notification management
  - State management

**Workflow Steps**:
1. Data validation
2. Data processing
3. Quality checks
4. Redshift loading
5. Catalog updates
6. Success/failure notifications

## Data Flow

### 1. Ingestion Phase
```
Source Systems → S3 Raw Data Bucket → Lambda Validation → Quality Gate
```

### 2. Processing Phase
```
Raw Data → Glue ETL Job → Transformed Data → S3 Processed Bucket
```

### 3. Loading Phase
```
Processed Data → Redshift Staging → Data Warehouse → Analytics Layer
```

## Configuration

### Environment Variables

**Lambda Function**:
```bash
GLUE_JOB_NAME=ecommerce-dwh-data-processing
PROCESSED_DATA_BUCKET=ecommerce-dwh-processed-data
GLUE_DATABASE_NAME=ecommerce_catalog
SNS_TOPIC_ARN=arn:aws:sns:ap-south-1:account:notifications
```

**Glue Jobs**:
```bash
--raw_data_bucket=ecommerce-dwh-raw-data
--processed_data_bucket=ecommerce-dwh-processed-data
--database_name=ecommerce_catalog
--redshift_connection=ecommerce-redshift-connection
```

### Data Quality Thresholds

```python
thresholds = {
    'completeness': 0.95,  # 95% completeness required
    'accuracy': 0.98,      # 98% accuracy required
    'consistency': 0.99,   # 99% consistency required
    'validity': 0.97       # 97% validity required
}
```

## Deployment

### 1. Deploy Infrastructure
```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### 2. Upload ETL Scripts
```bash
aws s3 cp etl/glue_jobs/ s3://your-scripts-bucket/glue_jobs/ --recursive
```

### 3. Create Glue Jobs
```bash
aws glue create-job --name ecommerce-dwh-data-processing \
  --role arn:aws:iam::account:role/GlueServiceRole \
  --command '{"Name":"glueetl","ScriptLocation":"s3://scripts-bucket/glue_jobs/data_processing.py"}'
```

### 4. Deploy Lambda Functions
```bash
cd etl/lambda_functions
zip -r data_validation.zip data_validation.py
aws lambda create-function --function-name ecommerce-dwh-data-validation \
  --runtime python3.9 --role arn:aws:iam::account:role/LambdaRole \
  --handler data_validation.lambda_handler --zip-file fileb://data_validation.zip
```

## Monitoring and Alerting

### CloudWatch Metrics
- ETL job success/failure rates
- Data processing volumes
- Quality check results
- Processing duration
- Error rates

### Alerts
- Data validation failures
- ETL job failures
- Quality threshold breaches
- Processing delays
- System errors

### Dashboards
- Pipeline health overview
- Data quality trends
- Processing performance
- Error analysis
- Business metrics

## Error Handling

### Retry Logic
- Lambda: 3 retries with exponential backoff
- Glue: 2 retries with 60-second intervals
- Step Functions: Configurable retry policies

### Error Categories
1. **Validation Errors**: Schema or quality issues
2. **Processing Errors**: Transformation failures
3. **System Errors**: Infrastructure issues
4. **Business Errors**: Rule violations

### Recovery Procedures
1. **Data Issues**: Manual data correction and reprocessing
2. **System Issues**: Automatic retries and failover
3. **Configuration Issues**: Parameter updates and restart

## Performance Optimization

### Glue Job Optimization
- Appropriate DPU allocation
- Partition pruning
- Columnar storage (Parquet)
- Compression (GZIP/Snappy)
- Broadcast joins for small tables

### Redshift Optimization
- Distribution keys for even data distribution
- Sort keys for query performance
- Compression encoding
- Vacuum and analyze automation
- Workload management (WLM)

### S3 Optimization
- Lifecycle policies for cost management
- Intelligent tiering
- Transfer acceleration
- Multipart uploads for large files

## Data Lineage

The pipeline maintains complete data lineage tracking:

```
Source → Raw S3 → Staging Tables → Dimension/Fact Tables → Analytics Views
```

**Lineage Metadata**:
- Source system identification
- Processing timestamps
- Transformation applied
- Quality check results
- Load statistics

## Testing

### Unit Tests
```bash
cd etl/tests
python -m pytest unit/ -v
```

### Integration Tests
```bash
python -m pytest integration/ -v
```

### End-to-End Tests
```bash
python -m pytest e2e/ -v
```

### Data Quality Tests
```bash
python -m pytest data_quality/ -v
```

## Troubleshooting

### Common Issues

1. **Schema Mismatch**: Update Glue catalog or fix source data
2. **Permission Errors**: Check IAM roles and policies
3. **Resource Limits**: Increase DPU or memory allocation
4. **Network Issues**: Verify VPC and security group settings

### Debug Commands

```bash
# Check Glue job logs
aws logs describe-log-groups --log-group-name-prefix /aws-glue/jobs

# Monitor Step Functions execution
aws stepfunctions describe-execution --execution-arn <arn>

# Check Lambda function logs
aws logs tail /aws/lambda/ecommerce-dwh-data-validation --follow
```

## Best Practices

1. **Data Validation**: Always validate data before processing
2. **Idempotency**: Ensure pipeline can be safely re-run
3. **Monitoring**: Implement comprehensive monitoring and alerting
4. **Documentation**: Maintain up-to-date documentation
5. **Testing**: Test thoroughly before production deployment
6. **Security**: Follow least privilege access principles
7. **Cost Optimization**: Monitor and optimize resource usage
8. **Backup**: Maintain data backups and recovery procedures
