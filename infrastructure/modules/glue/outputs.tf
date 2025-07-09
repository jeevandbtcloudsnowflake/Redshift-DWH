# Glue Module Outputs

output "catalog_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.main.name
}

output "catalog_database_arn" {
  description = "ARN of the Glue catalog database"
  value       = aws_glue_catalog_database.main.arn
}

output "redshift_connection_name" {
  description = "Name of the Redshift Glue connection"
  value       = aws_glue_connection.redshift.name
}

output "raw_data_crawler_name" {
  description = "Name of the raw data crawler"
  value       = aws_glue_crawler.raw_data.name
}

output "processed_data_crawler_name" {
  description = "Name of the processed data crawler"
  value       = aws_glue_crawler.processed_data.name
}

output "data_processing_job_name" {
  description = "Name of the data processing Glue job"
  value       = aws_glue_job.data_processing.name
}

output "data_quality_job_name" {
  description = "Name of the data quality Glue job"
  value       = aws_glue_job.data_quality.name
}
