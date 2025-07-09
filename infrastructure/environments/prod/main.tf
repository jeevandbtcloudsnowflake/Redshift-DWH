# Production Environment Configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for production
  backend "s3" {
    bucket = "ecommerce-dwh-terraform-state-prod"
    key    = "prod/terraform.tfstate"
    region = "ap-south-1"
    
    # DynamoDB table for state locking
    dynamodb_table = "ecommerce-dwh-terraform-locks-prod"
    encrypt        = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "E-Commerce Data Warehouse"
      ManagedBy   = "Terraform"
      CostCenter  = "DataEngineering"
      Owner       = "DataTeam"
    }
  }
}

# Backup region provider
provider "aws" {
  alias  = "backup_region"
  region = "ap-southeast-1"  # Singapore for DR
}

# Local values for production environment
locals {
  environment = "prod"
  
  common_tags = merge(var.common_tags, {
    Environment = local.environment
    Criticality = "High"
    Backup      = "Required"
  })
}

# Main E-commerce Data Warehouse Module
module "ecommerce_dwh" {
  source = "../../"

  # Project Configuration
  project_name = var.project_name
  environment  = local.environment
  aws_region   = var.aws_region

  # VPC Configuration (production-grade)
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Redshift Configuration (production-scale)
  redshift_cluster_identifier = "ecommerce-dwh-prod-cluster"
  redshift_node_type         = "ra3.4xlarge"  # Large nodes for production
  redshift_number_of_nodes   = 3              # Multi-node cluster
  redshift_master_username   = var.redshift_master_username
  redshift_master_password   = var.redshift_master_password

  # S3 Configuration
  s3_bucket_prefix = "ecommerce-dwh-prod"

  # Glue Configuration
  glue_database_name = "ecommerce_catalog_prod"

  # Step Functions Configuration
  step_functions_schedule = "cron(0 1 * * ? *)"  # 1 AM UTC for production

  # Tags
  common_tags = local.common_tags
}

# Production High Availability
module "high_availability" {
  source = "../../modules/high_availability"

  project_name = var.project_name
  environment  = local.environment
  
  # Multi-AZ deployment
  enable_multi_az = true
  
  # Auto-scaling configuration
  enable_auto_scaling = true
  min_capacity       = 3
  max_capacity       = 10
  target_utilization = 70
  
  # Load balancing
  enable_load_balancer = true
  
  tags = local.common_tags
}

# Production Security (Enhanced)
module "production_security" {
  source = "../../modules/security_advanced"

  project_name = var.project_name
  environment  = local.environment
  
  # Maximum security for production
  enable_config_rules     = true
  enable_security_hub     = true
  enable_guardduty       = true
  enable_inspector       = true
  enable_macie           = true  # Data classification
  enable_secrets_manager = true
  
  # Compliance requirements
  enable_cis_benchmarks  = true
  enable_pci_compliance  = true
  enable_sox_compliance  = true
  enable_gdpr_compliance = true
  
  # Advanced threat protection
  enable_waf             = true
  enable_shield_advanced = true
  
  tags = local.common_tags
}

# Production Backup & DR
module "production_backup" {
  source = "../../modules/backup"

  providers = {
    aws.backup_region = aws.backup_region
  }

  project_name = var.project_name
  environment  = local.environment
  
  # Production backup schedule
  backup_schedule = "cron(0 2 * * ? *)"  # Daily at 2 AM
  
  # Long-term retention
  backup_retention_days = 2555  # 7 years for compliance
  
  # Cross-region disaster recovery
  enable_cross_region_backup = true
  dr_region                 = "ap-southeast-1"
  
  # Point-in-time recovery
  enable_point_in_time_recovery = true
  
  # Backup encryption
  enable_backup_encryption = true
  
  tags = local.common_tags
}

# Production Monitoring & Alerting
module "production_monitoring" {
  source = "../../modules/monitoring_production"

  project_name = var.project_name
  environment  = local.environment
  
  # 24/7 monitoring
  enable_24x7_monitoring = true
  
  # Real-time alerting
  enable_real_time_alerts = true
  alert_endpoints = [
    "oncall@company.com",
    "dataeng-team@company.com"
  ]
  
  # SLA monitoring
  enable_sla_monitoring = true
  sla_targets = {
    availability = 99.9
    performance  = 95.0
    data_quality = 99.5
  }
  
  # Performance thresholds (strict for production)
  cpu_threshold    = 70
  memory_threshold = 75
  disk_threshold   = 80
  
  # Custom metrics
  enable_business_metrics = true
  
  tags = local.common_tags
}

# Production Cost Optimization
module "cost_optimization" {
  source = "../../modules/cost_optimization"

  project_name = var.project_name
  environment  = local.environment
  
  # Reserved instances for cost savings
  enable_reserved_instances = true
  
  # Automated scaling
  enable_cost_aware_scaling = true
  
  # Resource scheduling
  enable_resource_scheduling = true
  
  # Cost monitoring and alerts
  enable_cost_alerts = true
  monthly_budget     = 5000  # $5000/month budget
  
  tags = local.common_tags
}

# Production Data Governance
module "data_governance" {
  source = "../../modules/data_governance"

  project_name = var.project_name
  environment  = local.environment
  
  # Data catalog
  enable_data_catalog = true
  
  # Data lineage tracking
  enable_data_lineage = true
  
  # Data quality monitoring
  enable_data_quality_monitoring = true
  
  # Access control
  enable_fine_grained_access_control = true
  
  # Audit logging
  enable_comprehensive_audit_logging = true
  
  # Data retention policies
  enable_data_retention_policies = true
  
  tags = local.common_tags
}

# Production Performance Optimization
module "performance_optimization" {
  source = "../../modules/performance"

  project_name = var.project_name
  environment  = local.environment
  
  # Query optimization
  enable_query_optimization = true
  
  # Caching
  enable_result_caching = true
  
  # Compression
  enable_data_compression = true
  
  # Partitioning
  enable_automatic_partitioning = true
  
  # Performance monitoring
  enable_performance_insights = true
  
  tags = local.common_tags
}
