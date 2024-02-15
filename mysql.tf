// Create an iam-auth user for dev access
resource "mysql_user" "iam_user" {
  user        = var.rds_dev_user
  host        = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "iam_user" {
  user       = mysql_user.iam_user.user
  database   = "*"
  privileges = ["SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, SHOW VIEW, EVENT, REFERENCES, INDEX"]
  host       = "%"

  depends_on = [
    mysql_user.iam_user
  ]
}

// Create an iam-auth read-only user for dev access
resource "mysql_user" "iam_ro_user" {
  user        = var.rds_ro_user
  host        = "%"
  auth_plugin = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "iam_ro_user" {
  user       = mysql_user.iam_ro_user.user
  database   = "*"
  privileges = ["SELECT, SHOW DATABASES, SHOW VIEW"]
  host       = "%"

  depends_on = [
    mysql_user.iam_ro_user
  ]
}
