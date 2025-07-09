# Step Functions Module for Advanced ETL Orchestration

# Step Function State Machine
resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "${var.project_name}-${var.environment}-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "E-commerce ETL Pipeline with error handling and notifications"
    StartAt = "StartCrawler"
    States = {
      StartCrawler = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:startCrawler"
        Parameters = {
          Name = var.raw_data_crawler_name
        }
        Next = "WaitForCrawler"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 30
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "NotifyFailure"
          }
        ]
      }
      
      WaitForCrawler = {
        Type = "Wait"
        Seconds = 60
        Next = "CheckCrawlerStatus"
      }
      
      CheckCrawlerStatus = {
        Type = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler"
        Parameters = {
          Name = var.raw_data_crawler_name
        }
        Next = "IsCrawlerComplete"
      }
      
      IsCrawlerComplete = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.Crawler.State"
            StringEquals = "READY"
            Next = "StartDataProcessing"
          }
          {
            Variable = "$.Crawler.State"
            StringEquals = "RUNNING"
            Next = "WaitForCrawler"
          }
        ]
        Default = "NotifyFailure"
      }
      
      StartDataProcessing = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.data_processing_job_name
          Arguments = {
            "--raw_data_bucket" = var.raw_data_bucket
            "--processed_data_bucket" = var.processed_data_bucket
            "--database_name" = var.database_name
          }
        }
        Next = "StartDataQuality"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 60
            MaxAttempts = 2
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "NotifyFailure"
          }
        ]
      }
      
      StartDataQuality = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.data_quality_job_name
          Arguments = {
            "--processed_data_bucket" = var.processed_data_bucket
            "--database_name" = var.database_name
          }
        }
        Next = "NotifySuccess"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 60
            MaxAttempts = 2
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "NotifyFailure"
          }
        ]
      }
      
      NotifySuccess = {
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message = "ETL Pipeline completed successfully"
          Subject = "ETL Pipeline Success"
        }
        End = true
      }
      
      NotifyFailure = {
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message = "ETL Pipeline failed. Please check CloudWatch logs."
          Subject = "ETL Pipeline Failure"
        }
        End = true
      }
    }
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-etl-pipeline"
  })
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-${var.environment}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-${var.environment}-step-functions-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler",
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:BatchStopJobRun"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# CloudWatch Event Rule for Step Functions
resource "aws_cloudwatch_event_rule" "step_functions_schedule" {
  name                = "${var.project_name}-${var.environment}-step-functions-schedule"
  description         = "Trigger Step Functions ETL pipeline"
  schedule_expression = var.schedule_expression

  tags = var.tags
}

# CloudWatch Event Target for Step Functions
resource "aws_cloudwatch_event_target" "step_functions_target" {
  rule      = aws_cloudwatch_event_rule.step_functions_schedule.name
  target_id = "StepFunctionsTarget"
  arn       = aws_sfn_state_machine.etl_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-${var.environment}-eventbridge-role"

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

# IAM Policy for EventBridge
resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${var.project_name}-${var.environment}-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.etl_pipeline.arn
      }
    ]
  })
}
