# Glue Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue catalog database"
  type        = string
}

variable "service_role_arn" {
  description = "ARN of the Glue service role"
  type        = string
}

variable "scripts_bucket" {
  description = "S3 bucket for Glue scripts"
  type        = string
}

variable "raw_data_bucket" {
  description = "S3 bucket for raw data"
  type        = string
  default     = ""
}

variable "processed_data_bucket" {
  description = "S3 bucket for processed data"
  type        = string
  default     = ""
}

variable "redshift_jdbc_url" {
  description = "JDBC URL for Redshift connection"
  type        = string
  default     = ""
}

variable "redshift_username" {
  description = "Username for Redshift connection"
  type        = string
  default     = ""
}

variable "redshift_password" {
  description = "Password for Redshift connection"
  type        = string
  sensitive   = true
  default     = ""
}

variable "availability_zone" {
  description = "Availability zone for Glue connection"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "Security group IDs for Glue connection"
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet ID for Glue connection"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
