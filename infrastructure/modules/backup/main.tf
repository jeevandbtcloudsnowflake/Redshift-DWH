# Backup and Disaster Recovery Module

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-${var.environment}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backup-vault"
  })
}

# Backup Plan
resource "aws_backup_plan" "main" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC

    recovery_point_tags = merge(var.tags, {
      BackupType = "Daily"
    })

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.cross_region.arn

      lifecycle {
        cold_storage_after = 30
        delete_after       = 120
      }
    }
  }

  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 6 ? * SUN *)"  # Weekly on Sunday at 6 AM UTC

    recovery_point_tags = merge(var.tags, {
      BackupType = "Weekly"
    })

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }
  }

  tags = var.tags
}

# Cross-Region Backup Vault
resource "aws_backup_vault" "cross_region" {
  provider    = aws.backup_region
  name        = "${var.project_name}-${var.environment}-backup-vault-dr"
  kms_key_arn = var.dr_kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backup-vault-dr"
  })
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Selection
resource "aws_backup_selection" "redshift_backup" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.project_name}-${var.environment}-redshift-backup"
  plan_id      = aws_backup_plan.main.id

  resources = [
    var.redshift_cluster_arn
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Environment"
      value = var.environment
    }
  }
}

# S3 Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  count  = var.enable_s3_replication ? 1 : 0
  role   = aws_iam_role.s3_replication_role[0].arn
  bucket = var.source_bucket_id

  rule {
    id     = "replicate_all"
    status = "Enabled"

    destination {
      bucket        = var.destination_bucket_arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = var.dr_kms_key_arn
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.source_versioning]
}

resource "aws_s3_bucket_versioning" "source_versioning" {
  count  = var.enable_s3_replication ? 1 : 0
  bucket = var.source_bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "s3_replication_role" {
  count = var.enable_s3_replication ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "s3_replication_policy" {
  count = var.enable_s3_replication ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${var.source_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.source_bucket_arn
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${var.destination_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_replication_policy_attachment" {
  count      = var.enable_s3_replication ? 1 : 0
  role       = aws_iam_role.s3_replication_role[0].name
  policy_arn = aws_iam_policy.s3_replication_policy[0].arn
}

# Redshift Automated Snapshots Configuration
resource "aws_redshift_cluster" "snapshot_configuration" {
  count = var.configure_redshift_snapshots ? 1 : 0

  # This is a data source reference, not creating a new cluster
  cluster_identifier = var.redshift_cluster_identifier

  automated_snapshot_retention_period = var.snapshot_retention_days
  preferred_maintenance_window         = "sun:05:00-sun:06:00"
  
  # Manual snapshot before major changes
  final_snapshot_identifier = "${var.redshift_cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  skip_final_snapshot       = false

  tags = var.tags
}

# CloudWatch Alarms for Backup Monitoring
resource "aws_cloudwatch_metric_alarm" "backup_job_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-job-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors failed backup jobs"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  tags = var.tags
}

# Lambda Function for Backup Validation
resource "aws_lambda_function" "backup_validator" {
  filename         = "backup_validator.zip"
  function_name    = "${var.project_name}-${var.environment}-backup-validator"
  role            = aws_iam_role.backup_validator_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.backup_validator_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      BACKUP_VAULT_NAME = aws_backup_vault.main.name
      SNS_TOPIC_ARN     = var.sns_topic_arn
    }
  }

  tags = var.tags
}

data "archive_file" "backup_validator_zip" {
  type        = "zip"
  output_path = "backup_validator.zip"
  source {
    content = templatefile("${path.module}/backup_validator.py", {
      backup_vault_name = aws_backup_vault.main.name
    })
    filename = "index.py"
  }
}

resource "aws_iam_role" "backup_validator_role" {
  name = "${var.project_name}-${var.environment}-backup-validator-role"

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

  tags = var.tags
}

# EventBridge Rule for Backup Validation
resource "aws_cloudwatch_event_rule" "backup_completed" {
  name        = "${var.project_name}-${var.environment}-backup-completed"
  description = "Trigger backup validation when backup completes"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["COMPLETED"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "backup_validator_target" {
  rule      = aws_cloudwatch_event_rule.backup_completed.name
  target_id = "BackupValidatorTarget"
  arn       = aws_lambda_function.backup_validator.arn
}
