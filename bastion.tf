resource "aws_instance" "bastion" {
  depends_on                  = [module.vpc]
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_demo_key.id
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids      = [aws_security_group.demo_bastion_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  user_data                   = data.template_file.scripts.rendered

  tags = {
    Name = "Bastion"
  }
}

resource "aws_key_pair" "bastion_demo_key" {
  key_name   = "bastion_demo_key"
  public_key = var.ssh_public_key
}


resource "aws_security_group" "demo_bastion_sg" {
  name        = "Bastion SSH Access"
  description = "Bastion SSH Access"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 22 #If you wanted to be more secure you would change the port that SSH runs on using the user_data script.
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] #You will want to add your workstation ip/32 or your VPN's cidr here also. Depends on where you are wanting to connecto the bastion from.
    description = "Bastion SSH Access"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}





resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_iam_role.name
}

resource "aws_iam_role" "bastion_iam_role" {
  name               = "bastion_iam_role"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_policy_attach" {
  role       = aws_iam_role.bastion_iam_role.name
  policy_arn = aws_iam_policy.bastion_policy.arn
}

#IAM policy that is attached to our bastion. It allows a user that connects to it to carry over their permissions...ie. assume other policies.
resource "aws_iam_policy" "bastion_policy" {
  name   = "bastion_policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "IamPassRole",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "ec2.amazonaws.com"
                }
            }
        },
        {
            "Sid": "ListEc2AndListInstanceProfiles",
            "Effect": "Allow",
            "Action": [
                "iam:ListInstanceProfiles",
                "ec2:Describe*",
                "ec2:Search*",
                "ec2:Get*"
            ],
            "Resource": "*"
        }
    ]
}

EOF
}
