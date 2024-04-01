terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.43.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}


resource "aws_security_group" "cloudtictactoe_server_sg" {
  name        = "cloudtictactoe-server-sg"
  description = "Allows HTTP to web server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "cloudtictactoe_server" {
  ami                    = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 on us-east-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.cloudtictactoe_server_sg.id]

  user_data = "${file("setup-ec2.sh")}"

  tags = {
    Name = "Cloud Tic Tac Toe Instance"
  }
}
