terraform {
  required_version = "~> 1.14.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0, < 7.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    mysql = {
      source  = "terraform-providers/mysql"
      version = "~> 1.9"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }

}

provider "aws" {
  region = var.default_region

  default_tags {
    tags = {
      "Service_Name" = var.Service_Name
      "Owning_Team"  = var.Owning_Team
      "Automation"   = var.Automation
    }
  }
}

# Note: Terraform must have network connectivity to the RDS endpoint (VPN, AWS Client VPN, etc.).
# Use `terraform apply -target=module.mysql_rds` first if the provider reports a dependency cycle.
# If running imports, temporarily hardcode the endpoint and credentials to break the cycle.
provider "mysql" {
  endpoint = module.mysql_rds.mysql_rds_endpoint
  username = var.db_username
  password = random_password.password.result
}

# Connects using the admin password (same value stored in Secrets Manager). Mirrors the mysql provider above.
# Note: Terraform must have network connectivity to the RDS endpoint (VPN, AWS Client VPN, etc.).
# Use `terraform apply -target=module.psql_rds` first if the provider reports a dependency cycle.
provider "postgresql" {
  host     = module.psql_rds.psql_rds_endpoint
  port     = 5432
  database = "postgres"
  username = var.db_username
  password = random_password.password.result
  sslmode  = "require"
  superuser = false
}
