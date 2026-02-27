resource "aws_security_group" "psql_demo_rds_sg" {
  name        = "${var.Service_Name}_psql_instance"
  description = "${var.Service_Name} psql instance security group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "PSQL Access Port"
  }

}
