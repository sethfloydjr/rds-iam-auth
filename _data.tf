data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#For something more complicated than just a few easy install lines I would use something like Ansible to configure your instance here.
data "template_file" "scripts" {
  template = file("scripts/bastion.tpl")
  vars = {
    # If you needed to pass variables like AWS keys, user names, or any other vars into a script you could set that up here
    #dev_username    = "${var.dev_username}"
    #secret    = "${var.secret}"
  }
}
