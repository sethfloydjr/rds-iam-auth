resource "aws_security_group" "mysql_demo_rds_sg" {
  name        = "${var.Service_Name}_mysql_instance"
  description = "${var.Service_Name} mysql instance security group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "mysql Access Port"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
