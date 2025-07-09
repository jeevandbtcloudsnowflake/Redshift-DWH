# Team Guide: E-commerce Data Warehouse

## 🎯 **Quick Start for Team Members**

### **For Data Analysts**

#### **Connecting to Redshift**
1. **AWS Query Editor v2** (Recommended)
   - Go to AWS Console → Redshift → Query Editor v2
   - Connect to: `ecommerce-dwh-dev-cluster`
   - Database: `ecommerce_dwh_dev`
   - Username: `dwh_admin`

2. **BI Tools**
   - **Tableau**: Use PostgreSQL connector with Redshift endpoint
   - **Power BI**: Use PostgreSQL connector
   - **Looker/Metabase**: PostgreSQL connection

#### **Key Tables for Analysis**
```sql
-- Main fact table
SELECT * FROM facts.fact_sales LIMIT 10;

-- Customer dimension
SELECT * FROM dimensions.dim_customer LIMIT 10;

-- Product dimension  
SELECT * FROM dimensions.dim_product LIMIT 10;

-- Date dimension
SELECT * FROM dimensions.dim_date LIMIT 10;
```

#### **Pre-built Analytics Views**
```sql
-- Customer 360 view
SELECT * FROM analytics.customer_360 LIMIT 10;

-- Product performance
SELECT * FROM analytics.product_performance LIMIT 10;

-- Monthly trends
SELECT * FROM analytics.monthly_sales_trends;
```

### **For Data Engineers**

#### **ETL Pipeline Management**
```bash
# Run full ETL pipeline
aws glue start-crawler --name ecommerce-dwh-dev-raw-data-crawler --region ap-south-1
aws glue start-job-run --job-name ecommerce-dwh-dev-data-processing --region ap-south-1
aws glue start-job-run --job-name ecommerce-dwh-dev-data-quality --region ap-south-1
```

#### **Infrastructure Management**
```bash
# Deploy infrastructure changes
cd infrastructure/environments/dev
terraform plan
terraform apply

# Check infrastructure status
terraform output
```

#### **Data Quality Monitoring**
- Check CloudWatch dashboards
- Review data quality reports in S3
- Monitor Glue job execution logs

### **For DevOps Engineers**

#### **CI/CD Pipeline**
- **Terraform Plan**: Runs on pull requests
- **Terraform Apply**: Runs on main branch pushes
- **ETL Pipeline**: Scheduled daily at 2 AM UTC

#### **Monitoring & Alerts**
- **CloudWatch Dashboards**: Infrastructure metrics
- **Glue Job Monitoring**: ETL execution status
- **Redshift Performance**: Query and cluster metrics

#### **Security**
- All resources in private subnets
- IAM roles with least privilege
- Security groups with minimal access
- Encryption at rest and in transit

## 📊 **Common Business Questions & Queries**

### **1. Sales Performance**
```sql
-- Monthly revenue trend
SELECT 
    month_name,
    total_revenue,
    revenue_growth_percent
FROM analytics.monthly_sales_trends
ORDER BY year_number, month_number;
```

### **2. Customer Analysis**
```sql
-- Top customers by lifetime value
SELECT 
    full_name,
    customer_segment,
    lifetime_value,
    total_orders,
    customer_status
FROM analytics.customer_360
ORDER BY lifetime_value DESC
LIMIT 20;
```

### **3. Product Performance**
```sql
-- Best performing products
SELECT 
    product_name,
    category_name,
    total_revenue,
    gross_margin_percent,
    revenue_rank_in_category
FROM analytics.product_performance
WHERE revenue_rank_in_category <= 5
ORDER BY category_name, revenue_rank_in_category;
```

### **4. Geographic Analysis**
```sql
-- Sales by location
SELECT 
    state,
    city,
    total_revenue,
    revenue_per_customer,
    revenue_rank
FROM analytics.geographic_sales
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
```

## 🔧 **Development Workflow**

### **Adding New Data Sources**

1. **Create staging table**
   ```sql
   -- Add to sql/ddl/create_staging_tables.sql
   CREATE TABLE staging.stg_new_source (
       -- Define columns
   );
   ```

2. **Update ETL job**
   ```python
   # Modify etl/glue_jobs/data_processing.py
   # Add processing logic for new source
   ```

3. **Add data quality checks**
   ```python
   # Update etl/glue_jobs/data_quality.py
   # Add validation rules
   ```

4. **Deploy changes**
   ```bash
   # Commit changes and push
   git add .
   git commit -m "Add new data source"
   git push origin feature/new-data-source
   ```

### **Creating New Analytics**

1. **Write SQL query**
   ```sql
   -- Test in Redshift Query Editor
   SELECT ... FROM facts.fact_sales ...
   ```

2. **Create view (if reusable)**
   ```sql
   -- Add to sql/views/business_intelligence_views.sql
   CREATE OR REPLACE VIEW analytics.new_analysis AS
   SELECT ...
   ```

3. **Document the analysis**
   ```markdown
   # Add to docs/analytics/
   ## New Analysis
   - Purpose: ...
   - Key metrics: ...
   - Usage: ...
   ```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **ETL Job Failures**
1. Check Glue job logs in CloudWatch
2. Verify S3 data exists and is accessible
3. Check IAM permissions
4. Validate data format and schema

#### **Redshift Connection Issues**
1. Verify security group rules
2. Check VPC and subnet configuration
3. Confirm IAM role permissions
4. Test with AWS Query Editor first

#### **Data Quality Issues**
1. Review data quality reports in S3
2. Check source data for anomalies
3. Validate business rules in ETL jobs
4. Monitor data freshness metrics

### **Performance Optimization**

#### **Query Performance**
```sql
-- Check query performance
SELECT query, total_time, rows
FROM stl_query
WHERE userid > 1
ORDER BY total_time DESC
LIMIT 10;

-- Analyze table statistics
ANALYZE TABLE facts.fact_sales;
```

#### **Redshift Optimization**
- Monitor cluster utilization
- Adjust node count if needed
- Review sort and distribution keys
- Vacuum tables regularly

## 📞 **Support & Escalation**

### **Contact Information**
- **Data Engineering Team**: data-eng@company.com
- **DevOps Team**: devops@company.com
- **Business Intelligence**: bi@company.com

### **Escalation Path**
1. **Level 1**: Check documentation and logs
2. **Level 2**: Contact data engineering team
3. **Level 3**: Escalate to infrastructure team
4. **Level 4**: Engage AWS support if needed

### **Emergency Procedures**
- **Data Pipeline Failure**: Contact data engineering immediately
- **Security Incident**: Follow company security procedures
- **Infrastructure Outage**: Engage DevOps and AWS support

## 📚 **Additional Resources**

- [AWS Redshift Documentation](https://docs.aws.amazon.com/redshift/)
- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [SQL Style Guide](docs/sql-style-guide.md)
- [Data Governance Policies](docs/data-governance.md)
