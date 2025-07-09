# Glue Module for E-Commerce Data Warehouse

# Glue Catalog Database
resource "aws_glue_catalog_database" "main" {
  name        = var.database_name
  description = "Glue catalog database for ${var.project_name} ${var.environment}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-database"
  })
}

# Glue Connection for Redshift
resource "aws_glue_connection" "redshift" {
  name = "${var.project_name}-${var.environment}-redshift-connection"

  connection_properties = {
    JDBC_CONNECTION_URL = var.redshift_jdbc_url
    USERNAME           = var.redshift_username
    PASSWORD           = var.redshift_password
  }

  connection_type = "JDBC"

  physical_connection_requirements {
    availability_zone      = var.availability_zone
    security_group_id_list = var.security_group_ids
    subnet_id             = var.subnet_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-connection"
  })
}

# Glue Crawler for Raw Data
resource "aws_glue_crawler" "raw_data" {
  database_name = aws_glue_catalog_database.main.name
  name          = "${var.project_name}-${var.environment}-raw-data-crawler"
  role          = var.service_role_arn

  s3_target {
    path = "s3://${var.raw_data_bucket}/data/"
  }

  schedule = "cron(0 6 * * ? *)"  # Daily at 6 AM

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-raw-data-crawler"
  })
}

# Glue Crawler for Processed Data
resource "aws_glue_crawler" "processed_data" {
  database_name = aws_glue_catalog_database.main.name
  name          = "${var.project_name}-${var.environment}-processed-data-crawler"
  role          = var.service_role_arn

  s3_target {
    path = "s3://${var.processed_data_bucket}/processed/"
  }

  schedule = "cron(0 7 * * ? *)"  # Daily at 7 AM

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-processed-data-crawler"
  })
}

# Glue Workflow for ETL Orchestration
resource "aws_glue_workflow" "etl_workflow" {
  name        = "${var.project_name}-${var.environment}-etl-workflow"
  description = "Automated ETL workflow for e-commerce data processing"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-etl-workflow"
  })
}

# Workflow Triggers
resource "aws_glue_trigger" "start_crawler" {
  name         = "${var.project_name}-${var.environment}-start-crawler-trigger"
  type         = "ON_DEMAND"
  workflow_name = aws_glue_workflow.etl_workflow.name

  actions {
    crawler_name = aws_glue_crawler.raw_data.name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "start_processing" {
  name         = "${var.project_name}-${var.environment}-start-processing-trigger"
  type         = "CONDITIONAL"
  workflow_name = aws_glue_workflow.etl_workflow.name

  predicate {
    conditions {
      logical_operator = "EQUALS"
      crawler_name     = aws_glue_crawler.raw_data.name
      crawl_state      = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.data_processing.name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "start_quality" {
  name         = "${var.project_name}-${var.environment}-start-quality-trigger"
  type         = "CONDITIONAL"
  workflow_name = aws_glue_workflow.etl_workflow.name

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name         = aws_glue_job.data_processing.name
      state            = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.data_quality.name
  }

  tags = var.tags
}

# CloudWatch Event Rule for Scheduling
resource "aws_cloudwatch_event_rule" "etl_schedule" {
  name                = "${var.project_name}-${var.environment}-etl-schedule"
  description         = "Trigger ETL workflow daily"
  schedule_expression = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC

  tags = var.tags
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "etl_workflow_target" {
  rule      = aws_cloudwatch_event_rule.etl_schedule.name
  target_id = "GlueWorkflowTarget"
  arn       = "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workflow/${aws_glue_workflow.etl_workflow.name}"
  role_arn  = aws_iam_role.workflow_execution_role.arn
}

# IAM Role for Workflow Execution
resource "aws_iam_role" "workflow_execution_role" {
  name = "${var.project_name}-${var.environment}-workflow-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Workflow Execution
resource "aws_iam_role_policy" "workflow_execution_policy" {
  name = "${var.project_name}-${var.environment}-workflow-execution-policy"
  role = aws_iam_role.workflow_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartWorkflowRun",
          "glue:GetWorkflowRun",
          "glue:GetWorkflowRunProperties"
        ]
        Resource = aws_glue_workflow.etl_workflow.arn
      }
    ]
  })
}

# Data sources for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Glue Job for Data Processing
resource "aws_glue_job" "data_processing" {
  name         = "${var.project_name}-${var.environment}-data-processing"
  role_arn     = var.service_role_arn
  glue_version = "4.0"

  command {
    script_location = "s3://${var.scripts_bucket}/glue_jobs/data_processing.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${var.scripts_bucket}/spark-logs/"
    "--TempDir"                          = "s3://${var.scripts_bucket}/temp/"
    "--raw_data_bucket"                  = var.raw_data_bucket
    "--processed_data_bucket"            = var.processed_data_bucket
    "--database_name"                    = aws_glue_catalog_database.main.name
  }

  execution_property {
    max_concurrent_runs = 2
  }

  max_capacity = 2.0
  timeout      = 60

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-processing-job"
  })
}

# Glue Job for Data Quality
resource "aws_glue_job" "data_quality" {
  name         = "${var.project_name}-${var.environment}-data-quality"
  role_arn     = var.service_role_arn
  glue_version = "4.0"

  command {
    script_location = "s3://${var.scripts_bucket}/glue_jobs/data_quality.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                          = "s3://${var.scripts_bucket}/temp/"
    "--processed_data_bucket"            = var.processed_data_bucket
    "--database_name"                    = aws_glue_catalog_database.main.name
  }

  execution_property {
    max_concurrent_runs = 1
  }

  max_capacity = 1.0
  timeout      = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-quality-job"
  })
}
