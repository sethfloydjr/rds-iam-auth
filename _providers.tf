terraform {
  required_version = "~> 1.5.0, < 1.6.0"
  required_providers {
    aws = {
      version = "> 5.0.0, <6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }

}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      // This regex results in the terraform git repo name and any sub-directories.
      // This tag helps AWS UI users discover what Terraform git repo and directory to modify
      "Terraform Base Path" = replace(path.cwd, "/^.*?(${local.terraform-code-location}\\/)/", "$1")

      "Service_Name" = var.Service_Name
      "Owning_Team"  = var.Owning_Team
      "Automation"   = var.Automation
    }
  }
}

#Pulls the path for your code and uses it in a tag
locals {
  // Change the local variable to match the git repo name
  terraform-code-location = "RDS-IAM-AUTH"
}
