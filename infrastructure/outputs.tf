# Outputs for E-Commerce Data Warehouse Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# Redshift Outputs
output "redshift_cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = module.redshift.cluster_endpoint
  sensitive   = true
}

output "redshift_cluster_id" {
  description = "Redshift cluster identifier"
  value       = module.redshift.cluster_id
}

output "redshift_cluster_port" {
  description = "Redshift cluster port"
  value       = module.redshift.cluster_port
}

output "redshift_database_name" {
  description = "Redshift database name"
  value       = module.redshift.database_name
}

# S3 Outputs
output "s3_raw_data_bucket" {
  description = "S3 bucket for raw data"
  value       = module.s3.raw_data_bucket_name
}

output "s3_processed_data_bucket" {
  description = "S3 bucket for processed data"
  value       = module.s3.processed_data_bucket_name
}

output "s3_scripts_bucket" {
  description = "S3 bucket for scripts"
  value       = module.s3.scripts_bucket_name
}

# IAM Outputs
output "glue_service_role_arn" {
  description = "ARN of the Glue service role"
  value       = module.iam.glue_service_role_arn
}

output "redshift_service_role_arn" {
  description = "ARN of the Redshift service role"
  value       = module.iam.redshift_service_role_arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.iam.lambda_execution_role_arn
}

# Glue Outputs
output "glue_catalog_database_name" {
  description = "Name of the Glue catalog database"
  value       = module.glue.catalog_database_name
}

# Security Group Outputs
output "redshift_security_group_id" {
  description = "ID of the Redshift security group"
  value       = module.security.redshift_security_group_id
}

output "glue_security_group_id" {
  description = "ID of the Glue security group"
  value       = module.security.glue_security_group_id
}

# Glue Workflow Outputs
output "glue_etl_workflow_name" {
  description = "Name of the Glue ETL workflow"
  value       = module.glue.etl_workflow_name
}

output "glue_etl_workflow_arn" {
  description = "ARN of the Glue ETL workflow"
  value       = module.glue.etl_workflow_arn
}

output "glue_etl_schedule_rule_name" {
  description = "Name of the CloudWatch event rule for ETL scheduling"
  value       = module.glue.etl_schedule_rule_name
}

# Step Functions Outputs
output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_functions.state_machine_arn
}

output "step_functions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_functions.state_machine_name
}

output "step_functions_schedule_rule_name" {
  description = "Name of the CloudWatch event rule for Step Functions scheduling"
  value       = module.step_functions.schedule_rule_name
}

# QuickSight Outputs (conditional)
output "quicksight_console_url" {
  description = "URL to access QuickSight console"
  value       = var.enable_quicksight ? module.quicksight[0].quicksight_console_url : null
}

output "quicksight_data_source_arn" {
  description = "ARN of the QuickSight Redshift data source"
  value       = var.enable_quicksight ? module.quicksight[0].quicksight_data_source_arn : null
}

output "quicksight_dashboard_urls" {
  description = "URLs for accessing the QuickSight dashboards"
  value       = var.enable_quicksight ? module.quicksight[0].dashboard_urls : null
}
