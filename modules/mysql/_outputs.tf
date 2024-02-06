################################################################################
#                            RDS OUTPUTS
################################################################################
output "mysql_rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "mysql_rds_resource_id" {
  value = aws_db_instance.this.resource_id
}
