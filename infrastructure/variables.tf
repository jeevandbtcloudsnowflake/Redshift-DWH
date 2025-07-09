# Global Variables for E-Commerce Data Warehouse Infrastructure

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce-dwh"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "data-engineering-team"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

# Redshift Configuration
variable "redshift_cluster_identifier" {
  description = "Redshift cluster identifier"
  type        = string
  default     = "ecommerce-redshift-cluster"
}

variable "redshift_node_type" {
  description = "Redshift node type"
  type        = string
  default     = "ra3.xlplus"
}

variable "redshift_number_of_nodes" {
  description = "Number of Redshift nodes"
  type        = number
  default     = 2
}

variable "redshift_database_name" {
  description = "Redshift database name"
  type        = string
  default     = "ecommerce_dwh"
}

variable "redshift_master_username" {
  description = "Redshift master username"
  type        = string
  default     = "dwh_admin"
}

variable "redshift_master_password" {
  description = "Redshift master password"
  type        = string
  sensitive   = true
}

# S3 Configuration
variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket names"
  type        = string
  default     = "ecommerce-dwh"
}

# Glue Configuration
variable "glue_database_name" {
  description = "AWS Glue database name"
  type        = string
  default     = "ecommerce_catalog"
}

# Step Functions Configuration
variable "step_functions_schedule" {
  description = "CloudWatch Events schedule expression for Step Functions"
  type        = string
  default     = "cron(0 3 * * ? *)"  # Daily at 3 AM UTC (different from Glue Workflows)
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "E-Commerce Data Warehouse"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
