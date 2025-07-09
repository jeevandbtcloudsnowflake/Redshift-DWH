# Redshift Module Outputs

output "cluster_id" {
  description = "Redshift cluster identifier"
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = aws_redshift_cluster.main.endpoint
  sensitive   = true
}

output "cluster_port" {
  description = "Redshift cluster port"
  value       = aws_redshift_cluster.main.port
}

output "database_name" {
  description = "Redshift database name"
  value       = aws_redshift_cluster.main.database_name
}

output "cluster_arn" {
  description = "Redshift cluster ARN"
  value       = aws_redshift_cluster.main.arn
}

output "subnet_group_name" {
  description = "Redshift subnet group name"
  value       = aws_redshift_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Redshift parameter group name"
  value       = aws_redshift_parameter_group.main.name
}
