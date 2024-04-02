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

data "template_file" "setup-ec2-script" {
  template = file("setup-ec2.sh")
}

resource "aws_vpc" "cloudtictactoe_server_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Cloud Tic Tac Toe VPC"
  }
}

resource "aws_subnet" "cloudtictactoe_server_subnet1" {
  vpc_id     = aws_vpc.cloudtictactoe_server_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Cloud Tic Tac Toe Subnet 1"
  }
}

resource "aws_internet_gateway" "cloudtictactoe_server_gw" {
  vpc_id = aws_vpc.cloudtictactoe_server_vpc.id

  tags = {
    Name = "Cloud Tic Tac Toe Internet Gateway"
  }
}

resource "aws_route_table" "cloudtictactoe_server_rt" {
  vpc_id = aws_vpc.cloudtictactoe_server_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudtictactoe_server_gw.id
  }

  tags = {
    Name = "Cloud Tic Tac Toe Route Table"
  }
}

resource "aws_route_table_association" "cloudtictactoe_server_rta" {
  subnet_id      = aws_subnet.cloudtictactoe_server_subnet1.id
  route_table_id = aws_route_table.cloudtictactoe_server_rt.id
}

resource "aws_security_group" "cloudtictactoe_server_sg_http" {
  name        = "cloudtictactoe-server-sg-http"
  description = "Allows HTTP to web server"
  vpc_id      = aws_vpc.cloudtictactoe_server_vpc.id

  ingress {
    description = "HTTP ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Cloud Tic Tac Toe HTTP Security Group"
  }
}

resource "aws_security_group" "cloudtictactoe_server_sg_ssh" {
  name        = "cloudtictactoe-server-sg-ssh"
  description = "Allows SSH to web server"
  vpc_id      = aws_vpc.cloudtictactoe_server_vpc.id

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

  tags = {
    Name = "Cloud Tic Tac Toe SSH Security Group"
  }
}

resource "aws_instance" "cloudtictactoe_server" {
  ami           = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 on us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.cloudtictactoe_server_subnet1.id
  vpc_security_group_ids = [
    aws_security_group.cloudtictactoe_server_sg_http.id,
    aws_security_group.cloudtictactoe_server_sg_ssh.id
  ]
  associate_public_ip_address = true

  user_data = data.template_file.setup-ec2-script.rendered

  tags = {
    Name = "Cloud Tic Tac Toe Server Instance"
  }
}
