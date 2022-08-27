terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # equals to registry.terraform.io/hashicorp/aws
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-1"
}

## SSH Access Key
resource "aws_key_pair" "MyAccessKey" {
  key_name   = "kd"
  public_key = "ssh-ed25519 AAAAC***REPLACE_ME_AAAC user@localmachine"
}


## Security Group
resource "aws_security_group" "allow_web" {
  name        = var.instance_name
  description = "Allows access to ${var.instance_name}"

  # allow http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # allow https
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["213.144.156.32/32"]
  }

  # all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    environment = "dev"
    exercise    = "terraform exercise 2"
  }

  lifecycle {
    create_before_destroy = true
  }
} # security group ends here


## EC2 Instance
resource "aws_instance" "app_server" {
  ami           = "ami-07702eb3b2ef420a9"
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.support-resources-iam-profile.name
  key_name             = aws_key_pair.MyAccessKey.key_name

  tags = {
    Name        = var.instance_name
    environment = "dev"
    exercise    = "terraform exercise 2"
  }
}


## SSM Access with Role, EC2 Instance Profile, Role Attachment
resource "aws_iam_instance_profile" "support-resources-iam-profile" {
  name = "support_ec2_profile"
  role = aws_iam_role.support-resources-iam-role.name
}
resource "aws_iam_role" "support-resources-iam-role" {
  name               = "support-ssm-role"
  description        = "The role for the support resources EC2"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
}
EOF
  tags = {
    stack = "test"
  }
}
resource "aws_iam_role_policy_attachment" "support-resources-ssm-policy" {
  role       = aws_iam_role.support-resources-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
