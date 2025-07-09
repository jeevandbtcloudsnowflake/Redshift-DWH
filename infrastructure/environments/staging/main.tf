# Staging Environment Configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for staging
  backend "s3" {
    bucket = "ecommerce-dwh-terraform-state-staging"
    key    = "staging/terraform.tfstate"
    region = "ap-south-1"
    
    # DynamoDB table for state locking
    dynamodb_table = "ecommerce-dwh-terraform-locks-staging"
    encrypt        = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = "E-Commerce Data Warehouse"
      ManagedBy   = "Terraform"
    }
  }
}

# Local values for staging environment
locals {
  environment = "staging"
  
  common_tags = merge(var.common_tags, {
    Environment = local.environment
  })
}

# Main E-commerce Data Warehouse Module
module "ecommerce_dwh" {
  source = "../../"

  # Project Configuration
  project_name = var.project_name
  environment  = local.environment
  aws_region   = var.aws_region

  # VPC Configuration (larger for staging)
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  # Redshift Configuration (scaled up for staging)
  redshift_cluster_identifier = "ecommerce-dwh-staging-cluster"
  redshift_node_type         = "ra3.xlplus"
  redshift_number_of_nodes   = 2  # Multi-node for staging
  redshift_master_username   = var.redshift_master_username
  redshift_master_password   = var.redshift_master_password

  # S3 Configuration
  s3_bucket_prefix = "ecommerce-dwh-staging"

  # Glue Configuration
  glue_database_name = "ecommerce_catalog_staging"

  # Step Functions Configuration
  step_functions_schedule = "cron(0 4 * * ? *)"  # 4 AM UTC for staging

  # Tags
  common_tags = local.common_tags
}

# Staging-specific resources
module "staging_specific" {
  source = "../../modules/staging_specific"

  project_name = var.project_name
  environment  = local.environment
  
  # Production-like testing
  enable_performance_testing = true
  enable_load_testing       = true
  enable_integration_testing = true
  
  # Data volume for testing
  test_data_scale_factor = 10  # 10x dev data volume
  
  tags = local.common_tags
}

# Enhanced monitoring for staging
module "enhanced_monitoring" {
  source = "../../modules/monitoring_enhanced"

  project_name = var.project_name
  environment  = local.environment
  
  # Staging-specific monitoring
  enable_detailed_monitoring = true
  enable_performance_insights = true
  enable_cost_monitoring     = true
  
  # Alert thresholds (more relaxed than prod)
  cpu_threshold    = 80
  memory_threshold = 85
  disk_threshold   = 90
  
  tags = local.common_tags
}

# Security scanning for staging
module "security_scanning" {
  source = "../../modules/security_advanced"

  project_name = var.project_name
  environment  = local.environment
  
  # Enable all security features for staging validation
  enable_config_rules    = true
  enable_security_hub    = true
  enable_guardduty      = true
  enable_inspector      = true
  
  # Compliance scanning
  enable_cis_benchmarks = true
  enable_pci_compliance = true
  
  tags = local.common_tags
}

# Backup and DR testing
module "backup_testing" {
  source = "../../modules/backup"

  project_name = var.project_name
  environment  = local.environment
  
  # More frequent backups for staging testing
  backup_schedule = "cron(0 */6 * * ? *)"  # Every 6 hours
  
  # Cross-region replication for DR testing
  enable_cross_region_backup = true
  dr_region                 = "ap-southeast-1"
  
  # Backup validation
  enable_backup_validation = true
  
  tags = local.common_tags
}
