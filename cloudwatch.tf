resource "aws_sns_topic" "cpu_alarm_topic" {
  count = var.use_autoscaling ? 0 : 1

  name = "cpu-alarm-topic"
}

resource "aws_sns_topic" "instance_count_alarm_topic" {
  count = var.use_autoscaling ? 0 : 1
  
  name = "instance-count-alarm-topic"
}

resource "aws_sns_topic_subscription" "cpu_alarm_subscription" {
  count = var.use_autoscaling ? 0 : 1
  
  topic_arn = aws_sns_topic.cpu_alarm_topic[0].arn
  protocol  = "email"
  endpoint  = local.envs["CLOUDWATCH_ALARM_ENDPOINT"]
}

resource "aws_sns_topic_subscription" "instance_count_alarm_subscription" {
  count = var.use_autoscaling ? 0 : 1
  
  topic_arn = aws_sns_topic.instance_count_alarm_topic[0].arn
  protocol  = "email"
  endpoint  = local.envs["CLOUDWATCH_ALARM_ENDPOINT"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  count = var.use_autoscaling ? 0 : 1
  
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Monitors high CPU utilization"
  dimensions = {
    InstanceId = aws_instance.cloudtictactoe_server[0].id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm_topic[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "running_instances_alarm" {
  count = var.use_autoscaling ? 0 : 1
  
  alarm_name          = "no-running-instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Monitors if idle CPU utilization is lower than 1%, which could mean no EC2 instances are running"

  alarm_actions = [aws_sns_topic.instance_count_alarm_topic[0].arn]
}
