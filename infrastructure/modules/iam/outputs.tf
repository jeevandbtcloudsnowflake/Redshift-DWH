# IAM Module Outputs

output "redshift_service_role_arn" {
  description = "ARN of the Redshift service role"
  value       = aws_iam_role.redshift_service_role.arn
}

output "glue_service_role_arn" {
  description = "ARN of the Glue service role"
  value       = aws_iam_role.glue_service_role.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "redshift_service_role_name" {
  description = "Name of the Redshift service role"
  value       = aws_iam_role.redshift_service_role.name
}

output "glue_service_role_name" {
  description = "Name of the Glue service role"
  value       = aws_iam_role.glue_service_role.name
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}

output "redshift_scheduler_role_arn" {
  description = "ARN of the Redshift scheduler role"
  value       = aws_iam_role.redshift_scheduler_role.arn
}

output "redshift_scheduler_role_name" {
  description = "Name of the Redshift scheduler role"
  value       = aws_iam_role.redshift_scheduler_role.name
}
