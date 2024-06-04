resource "aws_launch_template" "cloudtictactoe_server" {
  count = var.use_autoscaling ? 1 : 0
  
  name_prefix   = "cloudtictactoe-server-"
  image_id      = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 on us-east-1
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.cloudtictactoe_server_subnet1.id
    security_groups             = [
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
  
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = [aws_subnet.cloudtictactoe_server_subnet1.id]
  launch_template {
    id      = aws_launch_template.cloudtictactoe_server[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "cloudtictactoe-server"
    propagate_at_launch = true
  }

  health_check_type           = "EC2"
  health_check_grace_period   = 300

  enabled_metrics = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMinSize", "GroupMaxSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
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
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Triggers when CPU utilization is high and scales out"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudtictactoe_asg[0].name
  }
  alarm_actions       = [aws_autoscaling_policy.scale_out[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  count = var.use_autoscaling ? 1 : 0
  
  alarm_name          = "low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "Triggers when CPU utilization is low and scales in"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudtictactoe_asg[0].name
  }
  alarm_actions       = [aws_autoscaling_policy.scale_in[0].arn]
}
