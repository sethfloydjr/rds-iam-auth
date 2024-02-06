# Create a role that is assumable
resource "aws_iam_role" "developer_db_role" {
  name = "psql_developer_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#Allows authorization into the demo DB through IAM for the `dev` db user
resource "aws_iam_role_policy_attachment" "service_policy_attchment" {
  role       = aws_iam_role.developer_db_role.name
  policy_arn = aws_iam_policy.rds_service_policy.arn
}

resource "aws_iam_policy" "rds_service_policy" {
  name        = "Demo-RDS-PSQL-Access"
  description = "Allows access through IAM for users to connect to RDS PSQL database"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds-db:connect"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:rds-db:${var.default_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.this.resource_id}/*"
    }
  ]

}
EOF
}
