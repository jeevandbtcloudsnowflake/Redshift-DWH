# Redshift Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_identifier" {
  description = "Redshift cluster identifier"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "master_username" {
  description = "Master username for the cluster"
  type        = string
}

variable "master_password" {
  description = "Master password for the cluster"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "Node type for the cluster"
  type        = string
  default     = "dc2.large"
}

variable "number_of_nodes" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the cluster"
  type        = list(string)
}

variable "iam_role_arn" {
  description = "IAM role ARN for the cluster"
  type        = string
}

variable "scheduler_role_arn" {
  description = "IAM role ARN for Redshift scheduler"
  type        = string
}

variable "logging_bucket_name" {
  description = "S3 bucket name for logging"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
