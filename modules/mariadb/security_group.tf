resource "aws_security_group" "mariadb_demo_rds_sg" {
  name        = "${var.Service_Name}_mariadb_instance"
  description = "${var.Service_Name} mariadb instance security group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "mariadb Access Port"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
