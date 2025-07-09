# Main Terraform configuration for E-Commerce Data Warehouse

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.common_tags, {
      Environment = var.environment
    })
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Region      = local.region
    AccountId   = local.account_id
  })
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  
  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  account_id   = local.account_id
  region       = local.region
  
  tags = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name    = var.project_name
  environment     = var.environment
  bucket_prefix   = var.s3_bucket_prefix
  
  tags = local.common_tags
}

# Redshift Module
module "redshift" {
  source = "./modules/redshift"

  project_name              = var.project_name
  environment               = var.environment
  cluster_identifier        = "${local.name_prefix}-cluster"
  node_type                = var.redshift_node_type
  number_of_nodes          = var.redshift_number_of_nodes
  database_name            = var.redshift_database_name
  master_username          = var.redshift_master_username
  master_password          = var.redshift_master_password
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  security_group_ids       = [module.security.redshift_security_group_id]
  iam_role_arn            = module.iam.redshift_service_role_arn
  scheduler_role_arn      = module.iam.redshift_scheduler_role_arn
  
  tags = local.common_tags
}

# Glue Module
module "glue" {
  source = "./modules/glue"

  project_name          = var.project_name
  environment           = var.environment
  database_name         = var.glue_database_name
  service_role_arn      = module.iam.glue_service_role_arn
  scripts_bucket        = module.s3.scripts_bucket_name
  raw_data_bucket       = module.s3.raw_data_bucket_name
  processed_data_bucket = module.s3.processed_data_bucket_name

  tags = local.common_tags
}

# CloudWatch Module
module "monitoring" {
  source = "./modules/monitoring"

  project_name           = var.project_name
  environment            = var.environment
  redshift_cluster_id    = module.redshift.cluster_id
  glue_database_name     = module.glue.catalog_database_name
  
  tags = local.common_tags
}
