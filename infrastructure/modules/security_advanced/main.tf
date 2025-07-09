# Advanced Security Module for DevOps

# AWS Config for Compliance Monitoring
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-config-delivery-channel"
  s3_bucket_name = var.config_bucket_name
}

# IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# CloudTrail for Audit Logging
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-${var.environment}-cloudtrail"
  s3_bucket_name = var.cloudtrail_bucket_name

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${var.data_bucket_arn}/*"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cloudtrail"
  })
}

# GuardDuty for Threat Detection
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-guardduty"
  })
}

# Secrets Manager for Sensitive Data
resource "aws_secretsmanager_secret" "redshift_credentials" {
  name        = "${var.project_name}-${var.environment}-redshift-credentials"
  description = "Redshift database credentials"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redshift_credentials" {
  secret_id = aws_secretsmanager_secret.redshift_credentials.id
  secret_string = jsonencode({
    username = var.redshift_username
    password = var.redshift_password
  })
}

# KMS Key for Encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-kms-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# Security Hub for Centralized Security Findings
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
}

# Config Rules for Compliance
resource "aws_config_config_rule" "s3_bucket_public_access_prohibited" {
  name = "${var.project_name}-${var.environment}-s3-bucket-public-access-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "redshift_cluster_configuration_check" {
  name = "${var.project_name}-${var.environment}-redshift-cluster-configuration-check"

  source {
    owner             = "AWS"
    source_identifier = "REDSHIFT_CLUSTER_CONFIGURATION_CHECK"
  }

  input_parameters = jsonencode({
    clusterDbEncrypted = "true"
    loggingEnabled     = "true"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# WAF for API Protection (if applicable)
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-${var.environment}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }

    action {
      block {}
    }
  }

  tags = var.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled    = true
  }
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_iam_role" "flow_log_role" {
  name = "${var.project_name}-${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "${var.project_name}-${var.environment}-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
