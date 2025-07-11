# 🚀 QuickSight Dashboard Deployment Guide

## 📋 Prerequisites

### 1. AWS Account Setup
- **QuickSight Account**: Enterprise edition recommended
- **IAM Permissions**: Admin access to QuickSight and Redshift
- **VPC Configuration**: Redshift cluster in private subnets

### 2. Infrastructure Requirements
- **Redshift Cluster**: Running and accessible
- **Analytics Views**: Deployed in Redshift
- **Sample Data**: Loaded for testing

### 3. Tools Required
- **Terraform**: v1.0 or later
- **Python**: 3.8 or later
- **AWS CLI**: Configured with appropriate credentials

## 🔧 Step-by-Step Deployment

### Step 1: Enable QuickSight in AWS Console

1. **Navigate to QuickSight Console**
   ```
   https://quicksight.aws.amazon.com/
   ```

2. **Sign up for QuickSight** (if not already done)
   - Choose **Enterprise** edition
   - Select **ap-south-1** region
   - Enable **VPC connections**

3. **Configure VPC Connection**
   - Go to **Manage QuickSight** → **Security & permissions**
   - Add VPC connection to your Redshift VPC

### Step 2: Deploy Infrastructure with Terraform

1. **Update terraform.tfvars**
   ```hcl
   # Enable QuickSight deployment
   enable_quicksight = true
   
   # Set admin email
   quicksight_admin_email = "your-email@company.com"
   ```

2. **Deploy Infrastructure**
   ```bash
   cd infrastructure/
   terraform init
   terraform plan -var="enable_quicksight=true"
   terraform apply
   ```

3. **Verify Deployment**
   ```bash
   # Check outputs
   terraform output quicksight_console_url
   terraform output quicksight_data_source_arn
   ```

### Step 3: Deploy Dashboards

1. **Automated Deployment**
   ```bash
   cd infrastructure/modules/quicksight/scripts/
   
   # Install dependencies
   pip install boto3
   
   # Deploy all dashboards
   python deploy_dashboards.py \
     --project-name ecommerce-dwh \
     --environment dev \
     --region ap-south-1
   ```

2. **Manual Deployment** (Alternative)
   - Use the JSON templates in `dashboard_templates/`
   - Import via QuickSight console
   - Configure data sources manually

### Step 4: Configure Permissions

1. **Share Dashboards**
   ```bash
   # Example: Share with specific users
   aws quicksight update-dashboard-permissions \
     --aws-account-id YOUR_ACCOUNT_ID \
     --dashboard-id ecommerce-dwh-dev-executive-dashboard \
     --grant-permissions Principal=arn:aws:quicksight:ap-south-1:ACCOUNT:user/default/USERNAME,Actions=quicksight:DescribeDashboard,quicksight:ListDashboardVersions,quicksight:QueryDashboard
   ```

2. **Create User Groups**
   - **Executives**: Access to Executive Dashboard
   - **Marketing**: Access to Customer Analytics
   - **Product**: Access to Product Performance
   - **Data Engineers**: Access to Operational Dashboard

## 📊 Dashboard Configuration

### Executive Dashboard
**URL Pattern**: `https://ap-south-1.quicksight.aws.amazon.com/sn/dashboards/ecommerce-dwh-dev-executive-dashboard`

**Key Features**:
- Revenue KPIs and trends
- Customer segment analysis
- Top product performance
- Monthly growth metrics

### Customer Analytics Dashboard
**URL Pattern**: `https://ap-south-1.quicksight.aws.amazon.com/sn/dashboards/ecommerce-dwh-dev-customer-dashboard`

**Key Features**:
- Customer 360 view
- RFM analysis
- Churn prediction
- Lifetime value metrics

### Product Performance Dashboard
**URL Pattern**: `https://ap-south-1.quicksight.aws.amazon.com/sn/dashboards/ecommerce-dwh-dev-product-dashboard`

**Key Features**:
- Product revenue rankings
- Category performance
- Margin analysis
- Inventory insights

### Operational Dashboard
**URL Pattern**: `https://ap-south-1.quicksight.aws.amazon.com/sn/dashboards/ecommerce-dwh-dev-operational-dashboard`

**Key Features**:
- Data freshness monitoring
- ETL job performance
- System health metrics
- Data quality scores

## 🔍 Verification & Testing

### 1. Data Source Connectivity
```sql
-- Test queries in QuickSight
SELECT COUNT(*) FROM analytics.customer_360;
SELECT COUNT(*) FROM analytics.product_performance;
SELECT COUNT(*) FROM analytics.monthly_sales_trends;
```

### 2. Dashboard Functionality
- **Filters**: Test date ranges and category filters
- **Drill-down**: Click on charts to explore details
- **Export**: Verify CSV/PDF export functionality
- **Refresh**: Check data refresh capabilities

### 3. Performance Testing
- **Query Speed**: Dashboards should load within 10 seconds
- **Concurrent Users**: Test with multiple users
- **Data Volume**: Verify performance with full dataset

## 🛠️ Troubleshooting

### Common Issues

1. **VPC Connection Failed**
   ```
   Error: Unable to connect to data source
   Solution: Check security groups and VPC configuration
   ```

2. **Dataset Not Found**
   ```
   Error: Dataset does not exist
   Solution: Verify Redshift views are created and accessible
   ```

3. **Permission Denied**
   ```
   Error: Access denied to dashboard
   Solution: Check QuickSight user permissions and sharing settings
   ```

### Debug Commands
```bash
# Check QuickSight data sources
aws quicksight list-data-sources --aws-account-id YOUR_ACCOUNT_ID

# Check datasets
aws quicksight list-data-sets --aws-account-id YOUR_ACCOUNT_ID

# Check dashboards
aws quicksight list-dashboards --aws-account-id YOUR_ACCOUNT_ID
```

## 📈 Post-Deployment Tasks

### 1. User Training
- Schedule dashboard training sessions
- Create user guides for each dashboard
- Set up support channels

### 2. Monitoring Setup
- Configure usage analytics
- Set up performance monitoring
- Create alerting for failures

### 3. Maintenance Schedule
- Weekly dashboard review
- Monthly performance optimization
- Quarterly user feedback collection

## 🔄 Updates & Maintenance

### Dashboard Updates
```bash
# Update dashboard templates
git pull origin main

# Redeploy dashboards
python deploy_dashboards.py \
  --project-name ecommerce-dwh \
  --environment dev \
  --region ap-south-1
```

### Infrastructure Updates
```bash
# Update Terraform configuration
terraform plan
terraform apply
```

## 📞 Support Contacts

- **Technical Issues**: data-engineering@company.com
- **Business Questions**: analytics@company.com
- **AWS Support**: Create support case in AWS Console

## 📚 Additional Resources

- [QuickSight User Guide](https://docs.aws.amazon.com/quicksight/)
- [Dashboard Best Practices](./QUICKSIGHT_DASHBOARDS.md)
- [Data Warehouse Documentation](../README.md)

---

**Last Updated**: 2025-01-11  
**Version**: 1.0  
**Next Review**: 2025-02-11
