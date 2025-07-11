# QuickSight Module Outputs

output "quicksight_data_source_arn" {
  description = "ARN of the QuickSight Redshift data source"
  value       = aws_quicksight_data_source.redshift.arn
}

output "quicksight_data_source_id" {
  description = "ID of the QuickSight Redshift data source"
  value       = aws_quicksight_data_source.redshift.data_source_id
}

output "quicksight_vpc_connection_arn" {
  description = "ARN of the QuickSight VPC connection"
  value       = aws_quicksight_vpc_connection.redshift.arn
}

output "quicksight_admin_user_arn" {
  description = "ARN of the QuickSight admin user"
  value       = aws_quicksight_user.admin.arn
}

output "customer_360_dataset_arn" {
  description = "ARN of the Customer 360 dataset"
  value       = aws_quicksight_data_set.customer_360.arn
}

output "product_performance_dataset_arn" {
  description = "ARN of the Product Performance dataset"
  value       = aws_quicksight_data_set.product_performance.arn
}

output "sales_trends_dataset_arn" {
  description = "ARN of the Sales Trends dataset"
  value       = aws_quicksight_data_set.sales_trends.arn
}

output "geographic_sales_dataset_arn" {
  description = "ARN of the Geographic Sales dataset"
  value       = aws_quicksight_data_set.geographic_sales.arn
}

output "quicksight_console_url" {
  description = "URL to access QuickSight console"
  value       = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/start"
}

output "dashboard_urls" {
  description = "URLs for accessing the dashboards"
  value = {
    executive_dashboard = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/dashboards/${var.project_name}-${var.environment}-executive-dashboard"
    customer_dashboard  = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/dashboards/${var.project_name}-${var.environment}-customer-dashboard"
    product_dashboard   = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/dashboards/${var.project_name}-${var.environment}-product-dashboard"
    operational_dashboard = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/dashboards/${var.project_name}-${var.environment}-operational-dashboard"
  }
}
