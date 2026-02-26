variable "default_region" {
  type    = string
  default = "us-east-1"
}


######### VPC VARS #########

variable "vpc_name" {
  type    = string
  default = "demo"
}

variable "vpc_cidr" {
  type        = string
  default     = "200.100.0.0/16"
  description = "16 available subnets - 4094 IP addresses per subnet"
}

variable "vpc_subnets" {
  type = map(list(string))
  default = {
    "azs"              = ["us-east-1a", "us-east-1b", "us-east-1c"]
    "private_subnets"  = ["200.100.0.0/20", "200.100.16.0/20", "200.100.32.0/20"]
    "public_subnets"   = ["200.100.48.0/20", "200.100.64.0/20", "200.100.80.0/20"]
    "database_subnets" = ["200.100.96.0/20", "200.100.112.0/20", "200.100.128.0/20"]
  }
}

######### RDS VARIABLES ##########
# Specific vars for your particular RDS type will be found in the module vars file for your type. /modules/your_type/variables.tf

# See here for more info:  https://aws.amazon.com/rds/instance-types/
variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_instance_identifier" {
  type    = string
  default = "iam-auth-demo"
}

variable "allow_major_version_upgrade" {
  type    = bool
  default = false
}

variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "storage_type" {
  type    = string
  default = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "standard"], var.storage_type)
    error_message = "storage_type must be one of: gp2, gp3, io1, io2, standard."
  }
}

variable "storage_encrypted" {
  type        = bool
  default     = true
  description = "Encrypt RDS storage at rest using KMS (AWS-managed key by default)."
}

variable "multi_az" {
  type        = bool
  default     = true
  description = "Deploy RDS in Multi-AZ mode for automatic failover. Doubles instance cost."
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "iam_database_authentication_enabled" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Prevents accidental database deletion. Must be disabled manually before destroy."
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Set to true only for dev/test environments. Always false in production."
}

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "Days to retain automated backups. Must be between 0 and 35."
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "backup_window" {
  type        = string
  default     = "05:30-07:30"
  description = "Daily UTC time range for automated backups. Must not overlap with maintenance_window."
}

variable "maintenance_window" {
  type        = string
  default     = "Sun:03:00-Sun:04:59"
  description = "Weekly UTC window for RDS maintenance. Syntax: ddd:hh24:mi-ddd:hh24:mi."
}

variable "rds_dev_user" {
  type    = string
  default = "developer"
}

variable "rds_ro_user" {
  type    = string
  default = "read_only"
}

######### MISC #########

variable "demo_ssm_parameter" {
  type        = string
  default     = "/database/demo"
  description = "SSM Parameter Store path where the database admin password is stored (SecureString)."
}

# ssh_public_key has no default — you must supply your public key contents at plan/apply time.
# Example: terraform apply -var='ssh_public_key=ssh-ed25519 AAAA...'
# The key pair is retained for break-glass emergency access if SSM Session Manager is unavailable.
variable "ssh_public_key" {
  type        = string
  description = "Contents of the SSH public key (.pub file) to install on the bastion for emergency access."
  sensitive   = true
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid SSH public key starting with a recognised key type (ssh-rsa, ssh-ed25519, ecdsa-sha2-*)."
  }
}


######### TAGS #########

variable "Service_Name" {
  type    = string
  default = "rds-demo"
}

variable "Owning_Team" {
  type    = string
  default = "YourTeam"
}

variable "Automation" {
  type    = string
  default = "terraform"
}
