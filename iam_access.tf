
# Create a user
resource "aws_iam_user" "john_smith" {
  name = "john.smith"
  path = "/"
}

# Give the new user some keys
resource "aws_iam_access_key" "john_smith_access_key" {
  user = aws_iam_user.john_smith.name
}


# Scoped policy: only allows rds-db:connect for the specific users on the specific RDS instances.
# This replaces the overly broad PowerUserAccess policy that was used for demo purposes.
resource "aws_iam_policy" "john_smith_rds_policy" {
  name        = "john-smith-rds-iam-connect"
  description = "Allows john.smith to connect to the demo RDS instances via IAM authentication only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RDSIAMConnect"
        Effect = "Allow"
        Action = ["rds-db:connect"]
        Resource = [
          "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.psql_rds.psql_rds_resource_id}/${var.rds_dev_user}",
          "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.psql_rds.psql_rds_resource_id}/${var.rds_ro_user}",
          "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.mysql_rds.mysql_rds_resource_id}/${var.rds_dev_user}",
          "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.mysql_rds.mysql_rds_resource_id}/${var.rds_ro_user}",
          "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.mariadb_rds.mariadb_rds_resource_id}/${var.rds_dev_user}",
          "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.mariadb_rds.mariadb_rds_resource_id}/${var.rds_ro_user}",
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_attachment" {
  user       = aws_iam_user.john_smith.name
  policy_arn = aws_iam_policy.john_smith_rds_policy.arn
}
