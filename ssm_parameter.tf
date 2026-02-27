resource "aws_secretsmanager_secret" "db_admin_password" {
  name                    = var.db_secret_name
  description             = "Admin password for the demo RDS instances (PostgreSQL, MySQL, MariaDB)"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_admin_password" {
  secret_id     = aws_secretsmanager_secret.db_admin_password.id
  secret_string = random_password.password.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "random_password" "password" {
  length           = 16
  numeric          = true
  special          = true
  upper            = true
  lower            = true
  override_special = "!#()-=+<>?"
  lifecycle {
    ignore_changes = [
      length,
      lower,
      upper,
      special,
      numeric
    ]
  }
}
