resource "aws_db_instance" "this" {
  instance_class                      = var.db_instance_class
  identifier                          = "${var.identifier}-mysql"
  engine                              = "mysql"
  engine_version                      = var.engine_version
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  allocated_storage                   = var.allocated_storage
  storage_type                        = var.storage_type
  username                            = var.username
  password                            = var.password
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  db_subnet_group_name                = var.db_subnet_group_name
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.backup_window
  maintenance_window                  = var.maintenance_window
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  final_snapshot_identifier           = "${var.engine}-${var.final_snapshot_identifier}"
  vpc_security_group_ids              = [aws_security_group.mysql_demo_rds_sg.id]
}
