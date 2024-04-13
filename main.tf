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

resource "aws_s3_bucket" "cloudtictactoe_server_bucket" {
  bucket = "cloudtictactoe-bucket-1"
  
  tags = {
    Name = "Cloud Tic Tac Toe S3 Bucket"
  }
}

resource "aws_s3_object" "cloudtictactoe_server_source_bundle" {
  bucket = aws_s3_bucket.cloudtictactoe_server_bucket.id
  key = "source-bundle.zip"
  source = "source-bundle.zip"
  etag = filemd5("source-bundle.zip")
}

resource "aws_elastic_beanstalk_application" "cloudtictactoe_app" {
  name = "Cloud Tic Tac Toe"
  description = "Cloud Tic Tac Toe Application"
}

resource "aws_elastic_beanstalk_application_version" "cloudtictactoe_app_version" {
  name = "v1.0.0"
  application = aws_elastic_beanstalk_application.cloudtictactoe_app.name
  description = "Cloud Tic Tac Toe Application Version 1.0.0"
  bucket = aws_s3_bucket.cloudtictactoe_server_bucket.id
  key = aws_s3_object.cloudtictactoe_server_source_bundle.id
}

resource "aws_elastic_beanstalk_environment" "cloudtictactoe_env" {
  name = "CloudTicTacToe-env"
  application = aws_elastic_beanstalk_application.cloudtictactoe_app.name
  version_label = aws_elastic_beanstalk_application_version.cloudtictactoe_app_version.name
  solution_stack_name = "64bit Amazon Linux 2 v3.8.0 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "LabInstanceProfile"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = aws_vpc.cloudtictactoe_server_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = aws_subnet.cloudtictactoe_server_subnet1.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = aws_subnet.cloudtictactoe_server_subnet1.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBScheme"
    value = "internetFacing"
  }

  # setting {
  #   namespace = "aws:elbv2:loadbalancer"
  #   name = "SecurityGroups"
  #   value = "${aws_security_group.cloudtictactoe_server_sg_http.id},${aws_security_group.cloudtictactoe_server_sg_ssh.id}"
  # }

  # setting {
  #   namespace = "aws:elasticbeanstalk:environment"
  #   name = "EnvironmentType"
  #   value = "LoadBalanced"
  # }

  # setting {
  #   namespace = "aws:elasticbeanstalk:environment"
  #   name = "LoadBalancerType"
  #   value = "application"
  # }

  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }
}