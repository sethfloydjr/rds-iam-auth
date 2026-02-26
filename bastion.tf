resource "aws_instance" "bastion" {
  depends_on                  = [module.vpc]
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true # Required for SSM outbound connectivity in a public subnet without VPC endpoints.
  key_name                    = aws_key_pair.bastion_demo_key.id # Retained for emergency break-glass SSH if SSM is unavailable.
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids      = [aws_security_group.demo_bastion_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  user_data                   = data.template_file.scripts.rendered

  tags = {
    Name = "Bastion"
  }
}

# Key pair kept for break-glass emergency access only.
# Normal access should use AWS Systems Manager Session Manager — no open ports required.
resource "aws_key_pair" "bastion_demo_key" {
  key_name   = "bastion_demo_key"
  public_key = var.ssh_public_key
}


# No inbound rules — SSH (port 22) has been removed.
# Access is provided exclusively via AWS Systems Manager Session Manager, which requires
# only outbound HTTPS (443) from the instance to the SSM service endpoint.
resource "aws_security_group" "demo_bastion_sg" {
  name        = "Bastion Access"
  description = "Bastion host — no inbound ports; outbound via SSM Session Manager only"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound (required for SSM and package installs)"
  }
}


resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_iam_role.name
}

resource "aws_iam_role" "bastion_iam_role" {
  name = "bastion_iam_role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

# Attach the AWS-managed SSM policy so Session Manager can connect without SSH.
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the scoped RDS connect policy so the bastion role itself can generate
# IAM auth tokens directly — no need to paste AWS credentials onto the instance.
resource "aws_iam_role_policy_attachment" "bastion_rds_policy_attach" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = aws_iam_policy.bastion_rds_policy.arn
}

# Least-privilege policy: allows the bastion to generate RDS IAM auth tokens for
# the specific developer and read-only users on each of the three RDS instances.
# This replaces the old iam:PassRole/* + ec2:Describe* wildcard policy.
resource "aws_iam_policy" "bastion_rds_policy" {
  name        = "bastion_rds_connect_policy"
  description = "Allows the bastion host to generate IAM auth tokens for the demo RDS instances"

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
