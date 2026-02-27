// Create an iam-auth developer user
resource "mysql_user" "iam_user" {
  user        = var.rds_dev_user
  host        = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "iam_user" {
  user     = mysql_user.iam_user.user
  database = "*"
  host     = "%"

  # Each privilege must be its own list element (not a single comma-separated string).
  # Removed from original:
  #   RELOAD  — system-level FLUSH operations; not appropriate for application developers.
  #   EVENT   — scheduled event management; not needed for standard application access.
  # Neither user has CREATE USER or GRANT OPTION, so they cannot create other users
  # or elevate privileges for themselves or others.
  privileges = [
    "SELECT",
    "INSERT",
    "UPDATE",
    "DELETE",
    "CREATE",
    "DROP",
    "ALTER",
    "SHOW DATABASES",
    "CREATE TEMPORARY TABLES",
    "LOCK TABLES",
    "CREATE VIEW",
    "SHOW VIEW",
    "REFERENCES",
    "INDEX",
  ]

  depends_on = [mysql_user.iam_user]
}

// Create an iam-auth read-only user
resource "mysql_user" "iam_ro_user" {
  user        = var.rds_ro_user
  host        = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "iam_ro_user" {
  user     = mysql_user.iam_ro_user.user
  database = "*"
  host     = "%"

  privileges = [
    "SELECT",
    "SHOW DATABASES",
    "SHOW VIEW",
  ]

  depends_on = [mysql_user.iam_ro_user]
}
