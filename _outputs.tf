################################################################################
#                            VPC OUTPUTS
################################################################################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  description = "List of availability_zones available for the VPC"
  value       = module.vpc.azs
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = module.vpc.database_subnet_group_name
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}



################################################################################
#                            BASTION OUTPUTS
################################################################################
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}


################################################################################
#                            USER OUTPUTS
################################################################################
output "access_key_secret" {
  value     = aws_iam_access_key.john_smith_access_key.secret
  sensitive = true
}



################################################################################
#                            PSQL RDS OUTPUTS
################################################################################
output "psql_rds_endpoint" {
  value = module.psql_rds.psql_rds_endpoint
}

output "psql_rds_resource_id" {
  value = module.psql_rds.psql_rds_resource_id
}



################################################################################
#                            MYSQL RDS OUTPUTS
################################################################################
output "mysql_rds_endpoint" {
  value = module.mysql_rds.mysql_rds_endpoint
}

output "mysql_rds_resource_id" {
  value = module.mysql_rds.mysql_rds_resource_id
}



################################################################################
#                            MARIADB RDS OUTPUTS
################################################################################
output "mariadb_rds_endpoint" {
  value = module.mariadb_rds.mariadb_rds_endpoint
}

output "mariadb_rds_resource_id" {
  value = module.mariadb_rds.mariadb_rds_resource_id
}
