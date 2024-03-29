#This sets up the password that will be used by you to access the instance as the `admin` user as defined in variables.tf
#This is a backdoor into the instance that a DBA or DevOps/SRE might use.
resource "aws_ssm_parameter" "ssm_parameter" {
  name  = var.demo_ssm_parameter
  type  = "String"
  value = random_password.password.result
}

resource "random_password" "password" {
  length           = 16
  numeric          = true
  special          = true
  upper            = true
  lower            = true
  override_special = "!#()-=+<>?"
  lifecycle {
    ignore_changes = [
      length,
      lower,
      upper,
      special,
      numeric
    ]
  }
}
