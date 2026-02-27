resource "aws_security_group" "mysql_demo_rds_sg" {
  name        = "${var.Service_Name}_mysql_instance"
  description = "${var.Service_Name} mysql instance security group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "MySQL Access Port"
  }

}
