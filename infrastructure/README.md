# E-Commerce Data Warehouse Infrastructure

This directory contains the Terraform Infrastructure as Code (IaC) for the E-Commerce Data Warehouse project.

## Architecture Overview

The infrastructure includes:
- **VPC** with public and private subnets across multiple AZs
- **Amazon Redshift** cluster for data warehousing
- **S3 buckets** for data storage (raw, processed, scripts, logs)
- **AWS Glue** for ETL processing and data catalog
- **IAM roles** and policies for secure access
- **CloudWatch** monitoring and alerting
- **Security groups** for network security

## Directory Structure

```
infrastructure/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Global variables
├── outputs.tf              # Global outputs
├── modules/                # Reusable Terraform modules
│   ├── vpc/               # VPC and networking
│   ├── security/          # Security groups
│   ├── iam/               # IAM roles and policies
│   ├── s3/                # S3 buckets
│   ├── redshift/          # Redshift cluster
│   ├── glue/              # AWS Glue resources
│   └── monitoring/        # CloudWatch monitoring
└── environments/          # Environment-specific configurations
    ├── dev/               # Development environment
    ├── staging/           # Staging environment
    └── prod/              # Production environment
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **AWS Account** with necessary permissions

## Quick Start

### 1. Clone and Navigate
```bash
cd infrastructure/environments/dev
```

### 2. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Deployment
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
terraform apply
```

## Environment Configuration

### Development Environment
- Single-node Redshift cluster (dc2.large)
- Smaller S3 storage classes
- Automated pause/resume for cost optimization
- Basic monitoring

### Staging Environment
- Multi-node Redshift cluster
- Production-like configuration
- Enhanced monitoring
- Data validation pipelines

### Production Environment
- Multi-node Redshift cluster with high availability
- Advanced monitoring and alerting
- Backup and disaster recovery
- Performance optimization

## Security Features

- **VPC Isolation**: All resources deployed in private subnets
- **Encryption**: S3 and Redshift encryption enabled
- **IAM**: Least privilege access policies
- **Security Groups**: Restrictive network access rules
- **VPC Endpoints**: Secure S3 access without internet gateway

## Cost Optimization

- **Lifecycle Policies**: Automatic S3 storage class transitions
- **Scheduled Actions**: Dev environment pause/resume
- **Right-sizing**: Environment-appropriate instance types
- **Monitoring**: Cost and usage tracking

## Monitoring and Alerting

- **CloudWatch Dashboards**: Real-time metrics visualization
- **Alarms**: Automated alerting for critical metrics
- **Log Groups**: Centralized logging for all services
- **SNS Topics**: Alert notifications

## Backup and Recovery

- **Automated Snapshots**: Redshift cluster backups
- **S3 Versioning**: Data version control
- **Cross-region Replication**: Disaster recovery (prod only)

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure AWS credentials have necessary permissions
2. **Resource Limits**: Check AWS service quotas
3. **Network Issues**: Verify VPC and security group configurations

### Useful Commands

```bash
# Check Terraform state
terraform state list

# Import existing resources
terraform import aws_s3_bucket.example bucket-name

# Refresh state
terraform refresh

# Destroy specific resource
terraform destroy -target=aws_instance.example
```

## Contributing

1. Follow Terraform best practices
2. Use consistent naming conventions
3. Add appropriate tags to all resources
4. Update documentation for any changes
5. Test in development environment first

## Support

For issues and questions:
- Create GitHub issues for bugs
- Use team Slack channel for questions
- Refer to AWS documentation for service-specific issues
