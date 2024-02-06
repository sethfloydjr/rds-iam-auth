variable "engine" {
  default = "postgres"
}

# Run the following command for the available versions:
# aws rds describe-db-engine-versions --default-only --engine postgres --region us-east-1
variable "engine_version" {
  default = "13.7"
}

variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql", "upgrade"]
}

data "aws_caller_identity" "current" {}
variable "default_region" {}
variable "db_instance_class" {}
variable "identifier" {}
variable "allow_major_version_upgrade" {}
variable "auto_minor_version_upgrade" {}
variable "allocated_storage" {}
variable "storage_type" {}
variable "username" {}
variable "password" {}
variable "iam_database_authentication_enabled" {}
variable "db_subnet_group_name" {}
variable "deletion_protection" {}
variable "skip_final_snapshot" {}
variable "backup_retention_period" {}
variable "backup_window" {}
variable "maintenance_window" {}
variable "final_snapshot_identifier" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "Service_Name" {}
