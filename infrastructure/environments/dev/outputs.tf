# Development Environment Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.ecommerce_dwh.vpc_id
}

output "redshift_cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = module.ecommerce_dwh.redshift_cluster_endpoint
  sensitive   = true
}

output "s3_raw_data_bucket" {
  description = "S3 bucket for raw data"
  value       = module.ecommerce_dwh.s3_raw_data_bucket
}

output "s3_processed_data_bucket" {
  description = "S3 bucket for processed data"
  value       = module.ecommerce_dwh.s3_processed_data_bucket
}

output "s3_scripts_bucket" {
  description = "S3 bucket for scripts"
  value       = module.ecommerce_dwh.s3_scripts_bucket
}

output "glue_catalog_database_name" {
  description = "Name of the Glue catalog database"
  value       = module.ecommerce_dwh.glue_catalog_database_name
}

# Glue Workflow Outputs
output "glue_etl_workflow_name" {
  description = "Name of the Glue ETL workflow"
  value       = module.ecommerce_dwh.glue_etl_workflow_name
}

output "glue_etl_workflow_arn" {
  description = "ARN of the Glue ETL workflow"
  value       = module.ecommerce_dwh.glue_etl_workflow_arn
}

output "glue_etl_schedule_rule_name" {
  description = "Name of the CloudWatch event rule for ETL scheduling"
  value       = module.ecommerce_dwh.glue_etl_schedule_rule_name
}
