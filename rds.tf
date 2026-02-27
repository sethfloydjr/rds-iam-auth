/*
Applying as-is will build all 3 RDS instances. To use only one engine type:
  1. Comment out the unneeded module blocks below.
  2. Remove the corresponding resource ARNs from the policy in iam_access.tf.
  3. Remove the corresponding provider from _providers.tf (mysql or postgresql).
*/

module "psql_rds" {
  source                              = "./modules/psql"
  depends_on                          = [module.vpc]
  default_region                      = var.default_region
  db_instance_class                   = var.db_instance_class
  identifier                          = var.db_instance_identifier
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  allocated_storage                   = var.allocated_storage
  storage_type                        = var.storage_type
  storage_encrypted                   = var.storage_encrypted
  multi_az                            = var.multi_az
  username                            = var.db_username
  password                            = random_password.password.result
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  db_subnet_group_name                = module.vpc.database_subnet_group_name
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.backup_window
  maintenance_window                  = var.maintenance_window
  final_snapshot_identifier           = var.db_instance_identifier
  vpc_id                              = module.vpc.vpc_id
  vpc_cidr                            = var.vpc_cidr
  Service_Name                        = var.Service_Name
  rds_dev_user                        = var.rds_dev_user
  rds_ro_user                         = var.rds_ro_user
}



module "mysql_rds" {
  source                              = "./modules/mysql"
  depends_on                          = [module.vpc]
  default_region                      = var.default_region
  db_instance_class                   = var.db_instance_class
  identifier                          = var.db_instance_identifier
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  allocated_storage                   = var.allocated_storage
  storage_type                        = var.storage_type
  storage_encrypted                   = var.storage_encrypted
  multi_az                            = var.multi_az
  username                            = var.db_username
  password                            = random_password.password.result
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  db_subnet_group_name                = module.vpc.database_subnet_group_name
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.backup_window
  maintenance_window                  = var.maintenance_window
  final_snapshot_identifier           = var.db_instance_identifier
  vpc_id                              = module.vpc.vpc_id
  vpc_cidr                            = var.vpc_cidr
  Service_Name                        = var.Service_Name
  rds_dev_user                        = var.rds_dev_user
  rds_ro_user                         = var.rds_ro_user
}



module "mariadb_rds" {
  source                              = "./modules/mariadb"
  depends_on                          = [module.vpc]
  default_region                      = var.default_region
  db_instance_class                   = var.db_instance_class
  identifier                          = var.db_instance_identifier
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  allocated_storage                   = var.allocated_storage
  storage_type                        = var.storage_type
  storage_encrypted                   = var.storage_encrypted
  multi_az                            = var.multi_az
  username                            = var.db_username
  password                            = random_password.password.result
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  db_subnet_group_name                = module.vpc.database_subnet_group_name
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.backup_window
  maintenance_window                  = var.maintenance_window
  final_snapshot_identifier           = var.db_instance_identifier
  vpc_id                              = module.vpc.vpc_id
  vpc_cidr                            = var.vpc_cidr
  Service_Name                        = var.Service_Name
  rds_dev_user                        = var.rds_dev_user
  rds_ro_user                         = var.rds_ro_user
}
