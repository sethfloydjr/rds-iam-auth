#Module homepage:  https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/
module "vpc" {
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "~> 5.1.1"
  name                         = var.vpc_name
  cidr                         = var.vpc_cidr
  azs                          = lookup(var.vpc_subnets, "azs")
  private_subnets              = lookup(var.vpc_subnets, "private_subnets")
  public_subnets               = lookup(var.vpc_subnets, "public_subnets")
  database_subnets             = lookup(var.vpc_subnets, "database_subnets")
  create_database_subnet_group = true
  enable_nat_gateway           = true
  enable_dns_support           = true
  enable_dns_hostnames         = true
}
