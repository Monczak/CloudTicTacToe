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

resource "aws_ecs_cluster" "cloudtictactoe_cluster" {
  name = "cloudtictactoe-cluster"
}

resource "aws_ecs_task_definition" "cloudtictactoe_task" {
  family = "cloudtictactoe-task"
  container_definitions = jsonencode([
    {
      name = "cloudtictactoe-frontend"
      image = "docker.io/monczak/cloudtictactoe-frontend-fargate:latest"
      portMappings = [
        {
          containerPort = 8002
          hostPort = 8002
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group" = "true"
          "awslogs-group" = "fargate-logs-test"
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name = "cloudtictactoe-backend"
      image = "docker.io/monczak/cloudtictactoe-backend-fargate:latest"
      portMappings = [
        {
          containerPort = 8001
          hostPort = 8001
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group" = "true"
          "awslogs-group" = "fargate-logs-test"
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name = "cloudtictactoe-web"
      image = "docker.io/monczak/cloudtictactoe-web-fargate:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group" = "true"
          "awslogs-group" = "fargate-logs-test"
          "awslogs-region" = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
  ])

  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  cpu = "256"
  memory = "0.5GB"

  execution_role_arn = "arn:aws:iam::854270513909:role/LabRole"
}

# resource "aws_lb_target_group" "cloudtictactoe_target_group" {
#   name = "cloudtictactoe-target-group"
#   port = 80
#   protocol = "TCP"
#   vpc_id = aws_vpc.cloudtictactoe_server_vpc.id
#   target_type = "ip"

#   health_check {
#     path = "/"
#     protocol = "HTTP"
#   }
# }

# resource "aws_lb_listener" "cloudtictactoe_listener" {
#   load_balancer_arn = aws_lb.cloudtictactoe_lb.arn
#   port = 80
#   protocol = "TCP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.cloudtictactoe_target_group.arn
#   }
# }

resource "aws_ecs_service" "cloudtictactoe_service" {
  name = "cloudtictactoe-service"
  cluster = aws_ecs_cluster.cloudtictactoe_cluster.id
  task_definition = aws_ecs_task_definition.cloudtictactoe_task.arn
  desired_count = 1
  launch_type = "FARGATE"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent = 100

  network_configuration {
    assign_public_ip = true
    security_groups = [ aws_security_group.cloudtictactoe_server_sg_http.id ]
    subnets = [ aws_subnet.cloudtictactoe_server_subnet1.id ]
  }
}