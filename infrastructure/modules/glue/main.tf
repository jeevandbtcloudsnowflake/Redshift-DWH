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
