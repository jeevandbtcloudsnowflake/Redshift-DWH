# S3 Module Outputs

output "raw_data_bucket_name" {
  description = "Name of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.bucket
}

output "raw_data_bucket_arn" {
  description = "ARN of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.arn
}

output "processed_data_bucket_name" {
  description = "Name of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.bucket
}

output "processed_data_bucket_arn" {
  description = "ARN of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.arn
}

output "scripts_bucket_name" {
  description = "Name of the scripts S3 bucket"
  value       = aws_s3_bucket.scripts.bucket
}

output "scripts_bucket_arn" {
  description = "ARN of the scripts S3 bucket"
  value       = aws_s3_bucket.scripts.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}
