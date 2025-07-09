# Step Functions Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "raw_data_crawler_name" {
  description = "Name of the raw data crawler"
  type        = string
}

variable "data_processing_job_name" {
  description = "Name of the data processing Glue job"
  type        = string
}

variable "data_quality_job_name" {
  description = "Name of the data quality Glue job"
  type        = string
}

variable "raw_data_bucket" {
  description = "Name of the raw data S3 bucket"
  type        = string
}

variable "processed_data_bucket" {
  description = "Name of the processed data S3 bucket"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue catalog database"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression"
  type        = string
  default     = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
