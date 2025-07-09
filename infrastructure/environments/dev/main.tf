# Development Environment Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "ecommerce-dwh/dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Use the main module
module "ecommerce_dwh" {
  source = "../../"

  # Environment specific variables
  environment                = "dev"
  project_name              = "ecommerce-dwh"
  aws_region                = "ap-south-1"

  # VPC Configuration
  vpc_cidr                  = "10.0.0.0/16"
  availability_zones        = ["ap-south-1a", "ap-south-1b"]
  
  # Redshift Configuration (smaller for dev)
  redshift_cluster_identifier = "ecommerce-dwh-dev-cluster"
  redshift_node_type         = "ra3.xlplus"
  redshift_number_of_nodes   = 1  # Single node for dev
  redshift_database_name     = "ecommerce_dwh_dev"
  redshift_master_username   = "dwh_admin"
  redshift_master_password   = var.redshift_master_password
  
  # S3 Configuration
  s3_bucket_prefix          = "ecommerce-dwh-dev"
  
  # Glue Configuration
  glue_database_name        = "ecommerce_catalog_dev"
  
  # Common tags
  common_tags = {
    Project     = "E-Commerce Data Warehouse"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "data-engineering-team"
    CostCenter  = "engineering"
  }
}
