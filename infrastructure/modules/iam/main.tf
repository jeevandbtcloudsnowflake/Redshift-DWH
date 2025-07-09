# IAM Module for E-Commerce Data Warehouse

# Redshift Service Role
resource "aws_iam_role" "redshift_service_role" {
  name = "${var.project_name}-${var.environment}-redshift-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-service-role"
  })
}

# Redshift S3 Access Policy
resource "aws_iam_policy" "redshift_s3_access" {
  name        = "${var.project_name}-${var.environment}-redshift-s3-access"
  description = "Policy for Redshift to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach S3 policy to Redshift role
resource "aws_iam_role_policy_attachment" "redshift_s3_access" {
  role       = aws_iam_role.redshift_service_role.name
  policy_arn = aws_iam_policy.redshift_s3_access.arn
}

# Glue Service Role
resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-${var.environment}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-service-role"
  })
}

# Attach AWS managed Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Glue S3 Access Policy
resource "aws_iam_policy" "glue_s3_access" {
  name        = "${var.project_name}-${var.environment}-glue-s3-access"
  description = "Policy for Glue to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach S3 policy to Glue role
resource "aws_iam_role_policy_attachment" "glue_s3_access" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

# Glue Redshift Access Policy
resource "aws_iam_policy" "glue_redshift_access" {
  name        = "${var.project_name}-${var.environment}-glue-redshift-access"
  description = "Policy for Glue to access Redshift"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "redshift:DescribeClusters",
          "redshift:GetClusterCredentials"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach Redshift policy to Glue role
resource "aws_iam_role_policy_attachment" "glue_redshift_access" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_redshift_access.arn
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-execution-role"
  })
}

# Attach AWS managed Lambda basic execution role policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach AWS managed Lambda VPC access execution role policy
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda S3 Access Policy
resource "aws_iam_policy" "lambda_s3_access" {
  name        = "${var.project_name}-${var.environment}-lambda-s3-access"
  description = "Policy for Lambda to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach S3 policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_access.arn
}

# Redshift Scheduler Service Role
resource "aws_iam_role" "redshift_scheduler_role" {
  name = "${var.project_name}-${var.environment}-redshift-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-scheduler-role"
  })
}

# Redshift Scheduler Policy
resource "aws_iam_policy" "redshift_scheduler_policy" {
  name        = "${var.project_name}-${var.environment}-redshift-scheduler-policy"
  description = "Policy for Redshift scheduler to pause/resume clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "redshift:PauseCluster",
          "redshift:ResumeCluster",
          "redshift:DescribeClusters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach scheduler policy to scheduler role
resource "aws_iam_role_policy_attachment" "redshift_scheduler_policy" {
  role       = aws_iam_role.redshift_scheduler_role.name
  policy_arn = aws_iam_policy.redshift_scheduler_policy.arn
}
