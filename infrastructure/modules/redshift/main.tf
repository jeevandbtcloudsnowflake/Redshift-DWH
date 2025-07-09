# Redshift Module for E-Commerce Data Warehouse

# Redshift Subnet Group
resource "aws_redshift_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-subnet-group"
  })
}

# Redshift Parameter Group
resource "aws_redshift_parameter_group" "main" {
  family = "redshift-1.0"
  name   = "${var.project_name}-${var.environment}-parameter-group"

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "max_concurrency_scaling_clusters"
    value = "1"
  }

  parameter {
    name  = "wlm_json_configuration"
    value = jsonencode([
      {
        query_group                = "default"
        query_group_wild_card      = 0
        user_group                 = "default"
        user_group_wild_card       = 0
        concurrency_scaling        = "auto"
        rules = [
          {
            rule_name      = "ETLRule"
            predicate      = "query_group='etl'"
            action         = "log"
          }
        ]
        auto_wlm                   = true
      }
    ])
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-parameter-group"
  })
}

# Redshift Cluster
resource "aws_redshift_cluster" "main" {
  cluster_identifier        = var.cluster_identifier
  database_name            = var.database_name
  master_username          = var.master_username
  master_password          = var.master_password
  node_type                = var.node_type
  cluster_type             = var.number_of_nodes > 1 ? "multi-node" : "single-node"
  number_of_nodes          = var.number_of_nodes > 1 ? var.number_of_nodes : null
  
  # Network configuration
  cluster_subnet_group_name = aws_redshift_subnet_group.main.name
  vpc_security_group_ids   = var.security_group_ids
  publicly_accessible      = false
  
  # Backup and maintenance
  automated_snapshot_retention_period = 7
  preferred_maintenance_window        = "sun:05:00-sun:06:00"
  skip_final_snapshot                = true
  
  # Performance and monitoring
  cluster_parameter_group_name = aws_redshift_parameter_group.main.name
  enhanced_vpc_routing     = true
  
  # IAM role
  iam_roles = [var.iam_role_arn]
  
  # Encryption
  encrypted = true
  
  # Logging (optional - can be enabled later)
  # logging {
  #   enable        = true
  #   bucket_name   = var.logging_bucket_name
  #   s3_key_prefix = "redshift-logs/"
  # }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-cluster"
  })

  depends_on = [
    aws_redshift_subnet_group.main,
    aws_redshift_parameter_group.main
  ]
}

# Redshift Scheduled Action for Pause/Resume (Cost Optimization)
# Disabled for initial deployment - can be enabled later
resource "aws_redshift_scheduled_action" "pause_cluster" {
  count = 0  # Disabled for now
  
  name        = "${var.project_name}-${var.environment}-pause-cluster"
  description = "Pause Redshift cluster during non-business hours"
  schedule    = "cron(0 22 * * MON-FRI *)"  # 10 PM weekdays
  iam_role    = var.scheduler_role_arn
  
  target_action {
    pause_cluster {
      cluster_identifier = aws_redshift_cluster.main.cluster_identifier
    }
  }

  depends_on = [aws_redshift_cluster.main]
}

resource "aws_redshift_scheduled_action" "resume_cluster" {
  count = 0  # Disabled for now
  
  name        = "${var.project_name}-${var.environment}-resume-cluster"
  description = "Resume Redshift cluster during business hours"
  schedule    = "cron(0 8 * * MON-FRI *)"   # 8 AM weekdays
  iam_role    = var.scheduler_role_arn
  
  target_action {
    resume_cluster {
      cluster_identifier = aws_redshift_cluster.main.cluster_identifier
    }
  }

  depends_on = [aws_redshift_cluster.main]
}
