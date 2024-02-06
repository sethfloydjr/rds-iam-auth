################################################################################
#                            RDS OUTPUTS
################################################################################
output "psql_rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "psql_rds_resource_id" {
  value = aws_db_instance.this.resource_id
}
