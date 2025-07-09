# Monitoring Module for E-Commerce Data Warehouse

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alerts"
  })
}

# CloudWatch Log Group for Glue Jobs
resource "aws_cloudwatch_log_group" "glue_jobs" {
  name              = "/aws-glue/jobs/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-logs"
  })
}

# CloudWatch Log Group for Lambda Functions
resource "aws_cloudwatch_log_group" "lambda_functions" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-logs"
  })
}

# CloudWatch Alarm for Redshift CPU Utilization
resource "aws_cloudwatch_metric_alarm" "redshift_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-redshift-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redshift cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterIdentifier = var.redshift_cluster_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-cpu-alarm"
  })
}

# CloudWatch Alarm for Redshift Database Connections
resource "aws_cloudwatch_metric_alarm" "redshift_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-redshift-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/Redshift"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "This metric monitors redshift database connections"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterIdentifier = var.redshift_cluster_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-connections-alarm"
  })
}

# CloudWatch Alarm for Glue Job Failures
resource "aws_cloudwatch_metric_alarm" "glue_job_failures" {
  alarm_name          = "${var.project_name}-${var.environment}-glue-job-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "Glue"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors glue job failures"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-failures-alarm"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Redshift", "CPUUtilization", "ClusterIdentifier", var.redshift_cluster_id],
            [".", "DatabaseConnections", ".", "."],
            [".", "NetworkReceiveThroughput", ".", "."],
            [".", "NetworkTransmitThroughput", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Redshift Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Glue", "glue.driver.aggregate.numCompletedTasks"],
            [".", "glue.driver.aggregate.numFailedTasks"],
            [".", "glue.driver.aggregate.numKilledTasks"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Glue Job Metrics"
          period  = 300
        }
      }
    ]
  })

  # CloudWatch dashboards don't support tags
}

# Data source for current region
data "aws_region" "current" {}
