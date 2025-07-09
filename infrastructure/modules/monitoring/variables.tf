# Monitoring Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "redshift_cluster_id" {
  description = "Redshift cluster identifier"
  type        = string
}

variable "glue_database_name" {
  description = "Glue database name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
