resource "aws_ecs_cluster" "cloudtictactoe_cluster" {
  name = "cloudtictactoe-cluster"

  tags = {
    Name = "Cloud Tic Tac Toe Cluster"
  }
}

resource "aws_cloudwatch_log_group" "cloudtictactoe_fargate_log_group" {
  name = "fargate-logs"

  tags = {
    Name = "CloudWatch Fargate Logs"
  }
}

variable "aws_ecs_log_configuration" {
  default = {
    logDriver = "awslogs"
    options = {
      "awslogs-create-group"  = "true"
      "awslogs-group"         = "fargate-logs"
      "awslogs-region"        = "us-east-1"
      "awslogs-stream-prefix" = "ecs"
    }
  }
}

resource "aws_ecs_task_definition" "cloudtictactoe_task" {
  family = "cloudtictactoe-task"
  container_definitions = jsonencode([
    {
      name  = "cloudtictactoe-frontend"
      image = "docker.io/monczak/cloudtictactoe-frontend-fargate:latest"
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      logConfiguration = var.aws_ecs_log_configuration
    },
    {
      name  = "cloudtictactoe-backend"
      image = "docker.io/monczak/cloudtictactoe-backend-fargate:latest"
      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
        }
      ]
      logConfiguration = var.aws_ecs_log_configuration
    },
    {
      name  = "cloudtictactoe-web"
      image = "docker.io/monczak/cloudtictactoe-web-fargate:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = var.aws_ecs_log_configuration
    },
  ])

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "0.5GB"

  execution_role_arn = "arn:aws:iam::854270513909:role/LabRole"

  tags = {
    Name        = "Cloud Tic Tac Toe Task Definition"
    Description = "Sets up the 3 Docker containers needed to run Cloud Tic Tac Toe."
  }
}

resource "aws_ecs_service" "cloudtictactoe_service" {
  name            = "cloudtictactoe-service"
  cluster         = aws_ecs_cluster.cloudtictactoe_cluster.id
  task_definition = aws_ecs_task_definition.cloudtictactoe_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.cloudtictactoe_server_sg_http.id]
    subnets          = [aws_subnet.cloudtictactoe_server_subnet1.id]
  }

  tags = {
    Name = "Cloud Tic Tac Toe Service"
  }
}