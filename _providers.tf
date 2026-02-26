terraform {
  required_version = "1.7.5"
  required_providers {
    aws = {
      version = "> 5.0.0, <6.0.0"
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
  region = "us-east-1"

  default_tags {
    tags = {
      "Service_Name" = var.Service_Name
      "Owning_Team"  = var.Owning_Team
      "Automation"   = var.Automation
    }
  }
}

provider "mysql" {
  // when running imports of resources it helps if you temporarily define these values manually to prevent a dependency cycle
  endpoint = module.psql_rds.psql_rds_endpoint
  username = "admin"
  password = random_password.password.result
}

# PostgreSQL provider for automated PSQL user provisioning.
# Connects using the admin password stored in SSM. Mirrors the mysql.tf approach.
# Note: Terraform must have network connectivity to the RDS endpoint (run from within the
# VPC or via a VPN/tunnel). Use `terraform apply -target=module.psql_rds` first if needed.
provider "postgresql" {
  host     = module.psql_rds.psql_rds_endpoint
  port     = 5432
  database = "postgres"
  username = var.db_username
  password = random_password.password.result
  sslmode  = "require"
  superuser = false
}
