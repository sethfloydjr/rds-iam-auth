# Remote State Backend (Template)
# -----------------------------------------------------------------------
# Uncomment and populate the values below to store Terraform state in S3
# with DynamoDB locking instead of locally on disk.
#
# Why this matters:
#   - Local state files contain sensitive values (passwords, access keys).
#   - Remote state is encrypted at rest (S3 SSE) and in transit (HTTPS).
#   - DynamoDB locking prevents concurrent applies from corrupting state.
#   - State is accessible to all team members without sharing files.
#
# Pre-requisites:
#   1. Create an S3 bucket with versioning and SSE enabled.
#   2. Create a DynamoDB table with a partition key named "LockID" (String).
#   3. Ensure the IAM principal running Terraform has s3:GetObject,
#      s3:PutObject, s3:DeleteObject on the key, and dynamodb:GetItem,
#      dynamodb:PutItem, dynamodb:DeleteItem on the table.
#
# After uncommenting, run `terraform init` to migrate existing local state.
# -----------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "YOUR_TERRAFORM_STATE_BUCKET_NAME"
#     key            = "rds-iam-auth/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "YOUR_TERRAFORM_LOCK_TABLE_NAME"
#   }
# }
