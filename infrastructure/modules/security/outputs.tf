# Security Module Outputs

output "redshift_security_group_id" {
  description = "ID of the Redshift security group"
  value       = aws_security_group.redshift.id
}

output "glue_security_group_id" {
  description = "ID of the Glue security group"
  value       = aws_security_group.glue.id
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda.id
}
