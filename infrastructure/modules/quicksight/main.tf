# QuickSight Module for E-commerce Data Warehouse
# Creates QuickSight data sources, datasets, and dashboards

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# QuickSight User (Admin)
resource "aws_quicksight_user" "admin" {
  aws_account_id = data.aws_caller_identity.current.account_id
  user_name      = var.quicksight_admin_user
  email          = var.quicksight_admin_email
  identity_type  = "IAM"
  user_role      = "ADMIN"
  
  tags = var.tags
}

# QuickSight Data Source - Redshift Connection
resource "aws_quicksight_data_source" "redshift" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_source_id = "${var.project_name}-${var.environment}-redshift-datasource"
  name           = "${var.project_name} ${title(var.environment)} Redshift Data Source"
  type           = "REDSHIFT"

  parameters {
    redshift {
      host     = var.redshift_endpoint
      port     = var.redshift_port
      database = var.redshift_database
    }
  }

  credentials {
    credential_pair {
      username = var.redshift_username
      password = var.redshift_password
    }
  }

  vpc_connection_properties {
    vpc_connection_arn = aws_quicksight_vpc_connection.redshift.arn
  }

  tags = var.tags
}

# VPC Connection for QuickSight to access Redshift
resource "aws_quicksight_vpc_connection" "redshift" {
  aws_account_id     = data.aws_caller_identity.current.account_id
  vpc_connection_id  = "${var.project_name}-${var.environment}-vpc-connection"
  name               = "${var.project_name} ${title(var.environment)} VPC Connection"
  role_arn           = aws_iam_role.quicksight_vpc.arn
  security_group_ids = var.security_group_ids
  subnet_ids         = var.private_subnet_ids

  tags = var.tags
}

# IAM Role for QuickSight VPC Connection
resource "aws_iam_role" "quicksight_vpc" {
  name = "${var.project_name}-${var.environment}-quicksight-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for QuickSight VPC Connection
resource "aws_iam_role_policy" "quicksight_vpc" {
  name = "${var.project_name}-${var.environment}-quicksight-vpc-policy"
  role = aws_iam_role.quicksight_vpc.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# QuickSight Dataset - Customer 360
resource "aws_quicksight_data_set" "customer_360" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_set_id    = "${var.project_name}-${var.environment}-customer-360"
  name           = "Customer 360 Analytics"
  import_mode    = "DIRECT_QUERY"

  physical_table_map {
    physical_table_id = "customer_360_table"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.redshift.arn
      name            = "Customer 360 View"
      sql_query       = "SELECT * FROM analytics.customer_360"
    }
  }

  tags = var.tags
}

# QuickSight Dataset - Product Performance
resource "aws_quicksight_data_set" "product_performance" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_set_id    = "${var.project_name}-${var.environment}-product-performance"
  name           = "Product Performance Analytics"
  import_mode    = "DIRECT_QUERY"

  physical_table_map {
    physical_table_id = "product_performance_table"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.redshift.arn
      name            = "Product Performance View"
      sql_query       = "SELECT * FROM analytics.product_performance"
    }
  }

  tags = var.tags
}

# QuickSight Dataset - Monthly Sales Trends
resource "aws_quicksight_data_set" "sales_trends" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_set_id    = "${var.project_name}-${var.environment}-sales-trends"
  name           = "Monthly Sales Trends"
  import_mode    = "DIRECT_QUERY"

  physical_table_map {
    physical_table_id = "sales_trends_table"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.redshift.arn
      name            = "Monthly Sales Trends View"
      sql_query       = "SELECT * FROM analytics.monthly_sales_trends"
    }
  }

  tags = var.tags
}

# QuickSight Dataset - Geographic Sales
resource "aws_quicksight_data_set" "geographic_sales" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_set_id    = "${var.project_name}-${var.environment}-geographic-sales"
  name           = "Geographic Sales Analytics"
  import_mode    = "DIRECT_QUERY"

  physical_table_map {
    physical_table_id = "geographic_sales_table"
    custom_sql {
      data_source_arn = aws_quicksight_data_source.redshift.arn
      name            = "Geographic Sales View"
      sql_query       = "SELECT * FROM analytics.geographic_sales"
    }
  }

  tags = var.tags
}

# Note: QuickSight dashboards are complex to define in Terraform
# We'll create the infrastructure and provide JSON templates for dashboard creation
# This approach is more practical and maintainable

# Local file for dashboard templates
resource "local_file" "dashboard_templates" {
  filename = "${path.module}/dashboard_templates.json"
  content = jsonencode({
    executive_dashboard = {
      name = "${var.project_name} ${title(var.environment)} Executive Dashboard"
      description = "Executive overview with KPIs, revenue trends, and customer insights"
      datasets = [
        aws_quicksight_data_set.sales_trends.arn,
        aws_quicksight_data_set.customer_360.arn,
        aws_quicksight_data_set.product_performance.arn
      ]
      visuals = [
        {
          type = "KPI"
          title = "Total Revenue"
          dataset = "sales_trends"
          measure = "total_revenue"
          aggregation = "SUM"
        },
        {
          type = "KPI"
          title = "Total Customers"
          dataset = "customer_360"
          measure = "customer_id"
          aggregation = "DISTINCT_COUNT"
        },
        {
          type = "LINE_CHART"
          title = "Monthly Revenue Trend"
          dataset = "sales_trends"
          x_axis = "month_name"
          y_axis = "total_revenue"
        },
        {
          type = "PIE_CHART"
          title = "Customer Segments"
          dataset = "customer_360"
          dimension = "customer_segment"
          measure = "lifetime_value"
        }
      ]
    }
    customer_dashboard = {
      name = "${var.project_name} ${title(var.environment)} Customer Analytics"
      description = "Customer 360 view with segmentation and behavior analysis"
      datasets = [
        aws_quicksight_data_set.customer_360.arn
      ]
      visuals = [
        {
          type = "TABLE"
          title = "Top Customers by Lifetime Value"
          dataset = "customer_360"
          columns = ["full_name", "customer_segment", "lifetime_value", "total_orders"]
        },
        {
          type = "BAR_CHART"
          title = "Customer Status Distribution"
          dataset = "customer_360"
          x_axis = "customer_status"
          y_axis = "customer_id"
          aggregation = "COUNT"
        }
      ]
    }
    product_dashboard = {
      name = "${var.project_name} ${title(var.environment)} Product Performance"
      description = "Product analytics with sales performance and profitability"
      datasets = [
        aws_quicksight_data_set.product_performance.arn
      ]
      visuals = [
        {
          type = "BAR_CHART"
          title = "Top Products by Revenue"
          dataset = "product_performance"
          x_axis = "product_name"
          y_axis = "total_revenue"
        },
        {
          type = "SCATTER_PLOT"
          title = "Revenue vs Margin Analysis"
          dataset = "product_performance"
          x_axis = "total_revenue"
          y_axis = "gross_margin_percent"
        }
      ]
    }
  })
}
