variable "default_region" {
  default = "us-east-1"
}


######### VPC VARS ######### 

variable "vpc_name" {
  default = "demo"
}

variable "vpc_cidr" {
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
  default = "db.t4g.micro"
}

variable "db_instance_identifier" {
  default = "iam-auth-demo"
}

variable "allow_major_version_upgrade" {
  default = "false"
}

variable "auto_minor_version_upgrade" {
  default = "true"
}

variable "allocated_storage" {
  default = "20"
}

variable "storage_type" {
  default = "gp2"
}

variable "db_username" {
  default = "admin"
}

variable "iam_database_authentication_enabled" {
  default = "true"
}

variable "deletion_protection" {
  default = "false"
}

variable "skip_final_snapshot" {
  default = "true"
}

variable "backup_retention_period" {
  default     = "7"
  description = "The days to retain backups for. Must be between 0 and 35. Must be greater than 0 if the database is used as a source for a Read Replica. "
}

variable "backup_window" {
  default     = "05:30-07:30"
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: `09:46-10:16`. Must not overlap with maintenance_window"
}

variable "maintenance_window" {
  default     = "Sun:03:00-Sun:04:59"
  description = "The window to perform maintenance in (in UTC). Syntax: `ddd:hh24:mi-ddd:hh24:mi`. Eg: `Mon:00:00-Mon:03:00`. "
}

variable "rds_dev_user" {
  default = "developer"
}

variable "rds_ro_user" {
  default = "read_only"
}

######### MISC #########


variable "demo_ssm_parameter" {
  default     = "/database/demo"
  description = "The location where the database password is kept."
}

variable "power_user_policy" {
  default     = "arn:aws:iam::aws:policy/PowerUserAccess"
  description = "AWS managed `support` user policy"
}

variable "ssh_public_key" {
  description = "Paste in the contents of your .pub key that you have already created locally."
  default     = "YOUR_PUB_KEY_GOES_HERE"
}


######### TAGS #########

variable "Service_Name" {
  default = "rds-demo"
}

variable "Owning_Team" {
  default = "YourTeam"
}

variable "Automation" {
  default = "terraform"
}

