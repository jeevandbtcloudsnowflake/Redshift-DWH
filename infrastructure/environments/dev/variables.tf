# Development Environment Variables

variable "redshift_master_password" {
  description = "Master password for Redshift cluster"
  type        = string
  sensitive   = true
}
