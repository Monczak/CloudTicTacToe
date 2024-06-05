# resource "aws_lb" "cloudtictactoe_alb" {
#   name               = "cloudtictactoe-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.cloudtictactoe_server_sg_http.id]
#   subnets            = [
#     aws_subnet.cloudtictactoe_server_subnet1.id,
#     aws_subnet.cloudtictactoe_server_subnet2.id
#   ]

#   enable_deletion_protection = false
# }

# resource "aws_lb_target_group" "cloudtictactoe_tg" {
#   name     = "cloudtictactoe-tg"
#   port     = 443
#   protocol = "TCP"
#   vpc_id   = aws_vpc.cloudtictactoe_server_vpc.id

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

# resource "aws_lb_listener" "https_listener" {
#   load_balancer_arn = aws_lb.cloudtictactoe_alb.arn
#   port              = "443"
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.cloudtictactoe_tg.arn
#   }
# }

resource "aws_launch_template" "cloudtictactoe_server" {
  count = var.use_autoscaling ? 1 : 0

  name_prefix   = "cloudtictactoe-server-"
  image_id      = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 on us-east-1
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.cloudtictactoe_server_subnet1.id
    security_groups = [
      aws_security_group.cloudtictactoe_server_sg_http.id,
      aws_security_group.cloudtictactoe_server_sg_ssh.id
    ]
  }

  user_data = base64encode(data.template_file.setup-ec2-script.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Cloud Tic Tac Toe Server Instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "cloudtictactoe_asg" {
  count = var.use_autoscaling ? 1 : 0

  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = [aws_subnet.cloudtictactoe_server_subnet1.id]

  launch_template {
    id      = aws_launch_template.cloudtictactoe_server[0].id
    version = "$Latest"
  }

  # target_group_arns = [aws_lb_target_group.cloudtictactoe_tg.arn]

  tag {
    key                 = "Name"
    value               = "cloudtictactoe-server"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 30
}


resource "aws_autoscaling_policy" "scale_out" {
  count = var.use_autoscaling ? 1 : 0

  name                   = "scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cloudtictactoe_asg[0].name
}

resource "aws_autoscaling_policy" "scale_in" {
  count = var.use_autoscaling ? 1 : 0

  name                   = "scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cloudtictactoe_asg[0].name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  count = var.use_autoscaling ? 1 : 0

  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when CPU utilization is high and scales out"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudtictactoe_asg[0].name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out[0].arn, aws_sns_topic.cpu_alarm_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  count = var.use_autoscaling ? 1 : 0

  alarm_name          = "low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Triggers when CPU utilization is low and scales in"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudtictactoe_asg[0].name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in[0].arn]
}
