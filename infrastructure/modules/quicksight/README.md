# 📊 QuickSight Module

## Overview

This Terraform module creates Amazon QuickSight infrastructure for business intelligence dashboards connected to the Redshift data warehouse.

## Features

- **Data Sources**: Redshift connection with VPC support
- **Datasets**: Pre-configured datasets for analytics views
- **Dashboard Templates**: JSON templates for 4 comprehensive dashboards
- **Automated Deployment**: Python scripts for dashboard creation
- **Security**: IAM roles and VPC connections

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Redshift      │    │   QuickSight    │    │   Dashboards    │
│   Data Source   │───▶│   Datasets      │───▶│   & Analytics   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    ┌─────────┐            ┌─────────┐            ┌─────────┐
    │Analytics│            │   VPC   │            │Business │
    │  Views  │            │Connection│            │ Users   │
    └─────────┘            └─────────┘            └─────────┘
```

## Resources Created

### Core Infrastructure
- **QuickSight Data Source** - Redshift connection
- **QuickSight VPC Connection** - Secure network access
- **QuickSight Datasets** - 4 pre-configured datasets
- **IAM Roles** - Service permissions

### Datasets
1. **Customer 360** - Complete customer analytics
2. **Product Performance** - Product sales and profitability
3. **Sales Trends** - Time-series sales analysis
4. **Geographic Sales** - Location-based performance

### Dashboard Templates
1. **Executive Dashboard** - High-level KPIs and trends
2. **Customer Analytics** - Customer segmentation and behavior
3. **Product Performance** - Product and category analysis
4. **Operational Dashboard** - Data engineering metrics

## Usage

### Basic Usage
```hcl
module "quicksight" {
  source = "./modules/quicksight"

  project_name           = "ecommerce-dwh"
  environment           = "dev"
  quicksight_admin_email = "admin@company.com"
  
  # Redshift connection
  redshift_endpoint  = "cluster.xyz.redshift.amazonaws.com"
  redshift_port      = 5439
  redshift_database  = "ecommerce_dwh"
  redshift_username  = "dwh_admin"
  redshift_password  = "secure_password"
  
  # Network configuration
  vpc_id             = "vpc-12345"
  private_subnet_ids = ["subnet-123", "subnet-456"]
  security_group_ids = ["sg-789"]

  tags = {
    Environment = "dev"
    Project     = "E-Commerce DWH"
  }
}
```

### With Optional Features
```hcl
module "quicksight" {
  source = "./modules/quicksight"

  # ... basic configuration ...
  
  # Dashboard controls
  enable_executive_dashboard   = true
  enable_customer_dashboard    = true
  enable_product_dashboard     = true
  enable_operational_dashboard = true
  
  # User management
  quicksight_users = [
    {
      username      = "john.doe"
      email         = "john.doe@company.com"
      user_role     = "AUTHOR"
      identity_type = "IAM"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment (dev, staging, prod) | `string` | n/a | yes |
| quicksight_admin_email | Admin email address | `string` | n/a | yes |
| redshift_endpoint | Redshift cluster endpoint | `string` | n/a | yes |
| redshift_port | Redshift cluster port | `number` | `5439` | no |
| redshift_database | Redshift database name | `string` | n/a | yes |
| redshift_username | Redshift username | `string` | n/a | yes |
| redshift_password | Redshift password | `string` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| private_subnet_ids | Private subnet IDs | `list(string)` | n/a | yes |
| security_group_ids | Security group IDs | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| quicksight_data_source_arn | ARN of the QuickSight data source |
| quicksight_console_url | URL to access QuickSight console |
| dashboard_urls | URLs for accessing dashboards |
| customer_360_dataset_arn | ARN of Customer 360 dataset |
| product_performance_dataset_arn | ARN of Product Performance dataset |

## Dashboard Deployment

### Automated Deployment
```bash
cd scripts/
python deploy_dashboards.py \
  --project-name ecommerce-dwh \
  --environment dev \
  --region ap-south-1
```

### Manual Deployment
1. Use JSON templates in `dashboard_templates/`
2. Import via QuickSight console
3. Configure data source connections

## File Structure

```
quicksight/
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
├── README.md                   # This file
├── dashboard_templates/        # Dashboard JSON templates
│   ├── executive_dashboard.json
│   ├── customer_dashboard.json
│   ├── product_dashboard.json
│   └── operational_dashboard.json
└── scripts/                    # Deployment scripts
    └── deploy_dashboards.py    # Automated deployment
```

## Prerequisites

1. **QuickSight Account** - Enterprise edition recommended
2. **Redshift Cluster** - Running and accessible
3. **Analytics Views** - Deployed in Redshift database
4. **VPC Configuration** - Proper networking setup

## Security Considerations

- **VPC Connection** - Secure access to Redshift
- **IAM Roles** - Least privilege access
- **Encryption** - Data encrypted in transit and at rest
- **Access Control** - Dashboard-level permissions

## Troubleshooting

### Common Issues

1. **VPC Connection Failed**
   - Check security group rules
   - Verify subnet configuration
   - Ensure Redshift accessibility

2. **Dataset Creation Failed**
   - Verify analytics views exist
   - Check Redshift permissions
   - Validate SQL queries

3. **Dashboard Deployment Failed**
   - Check dataset ARNs
   - Verify JSON template syntax
   - Ensure QuickSight permissions

## Cost Optimization

- **Direct Query** - No SPICE storage costs
- **Shared Dashboards** - Reduce per-user costs
- **Scheduled Refresh** - Optimize query frequency

## Monitoring

- **Usage Analytics** - Track dashboard adoption
- **Performance Metrics** - Monitor query times
- **Error Logging** - CloudWatch integration

## Support

- **Documentation**: [QuickSight Dashboards Guide](../../../docs/QUICKSIGHT_DASHBOARDS.md)
- **Deployment**: [Deployment Guide](../../../docs/QUICKSIGHT_DEPLOYMENT_GUIDE.md)
- **Issues**: Create GitHub issue or contact data engineering team

---

**Version**: 1.0  
**Last Updated**: 2025-01-11  
**Maintained by**: Data Engineering Team
