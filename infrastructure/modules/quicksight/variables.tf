# QuickSight Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# QuickSight Configuration
variable "quicksight_admin_user" {
  description = "QuickSight admin username"
  type        = string
  default     = "quicksight-admin"
}

variable "quicksight_admin_email" {
  description = "QuickSight admin email address"
  type        = string
}

# Redshift Connection Details
variable "redshift_endpoint" {
  description = "Redshift cluster endpoint"
  type        = string
}

variable "redshift_port" {
  description = "Redshift cluster port"
  type        = number
  default     = 5439
}

variable "redshift_database" {
  description = "Redshift database name"
  type        = string
}

variable "redshift_username" {
  description = "Redshift username for QuickSight connection"
  type        = string
}

variable "redshift_password" {
  description = "Redshift password for QuickSight connection"
  type        = string
  sensitive   = true
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where Redshift is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for QuickSight VPC connection"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for QuickSight VPC connection"
  type        = list(string)
}

# Dashboard Configuration
variable "enable_executive_dashboard" {
  description = "Enable executive dashboard creation"
  type        = bool
  default     = true
}

variable "enable_customer_dashboard" {
  description = "Enable customer analytics dashboard creation"
  type        = bool
  default     = true
}

variable "enable_product_dashboard" {
  description = "Enable product performance dashboard creation"
  type        = bool
  default     = true
}

variable "enable_operational_dashboard" {
  description = "Enable operational dashboard creation"
  type        = bool
  default     = true
}

# QuickSight Permissions
variable "quicksight_users" {
  description = "List of QuickSight users to create"
  type = list(object({
    username      = string
    email         = string
    user_role     = string # ADMIN, AUTHOR, READER
    identity_type = string # IAM, QUICKSIGHT
  }))
  default = []
}

variable "dashboard_permissions" {
  description = "Dashboard sharing permissions"
  type = object({
    actions = list(string)
    principals = list(string)
  })
  default = {
    actions = [
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboardVersions",
      "quicksight:QueryDashboard"
    ]
    principals = []
  }
}
