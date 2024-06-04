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

data "external" "make_lambda" {
  program = ["bash", "${path.module}/make-lambda.sh"]
}

resource "aws_lambda_function" "check_running_instances" {
  count = var.use_autoscaling ? 0 : 1

  depends_on = [ data.external.make_lambda ]

  filename         = ".tmp/check_running_instances.zip"
  function_name    = "CheckRunningInstances"
  role             = local.envs["AWS_ROLE_ARN"]
  handler          = "check_running_instances.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256(".tmp/check_running_instances.zip")
}

resource "aws_cloudwatch_event_rule" "every_minute" {
  count = var.use_autoscaling ? 0 : 1
  
  name        = "every_minute"
  description = "Fires every minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "check_running_instances_target" {
  count = var.use_autoscaling ? 0 : 1
  
  rule = aws_cloudwatch_event_rule.every_minute[0].name
  arn  = aws_lambda_function.check_running_instances[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  count = var.use_autoscaling ? 0 : 1
  
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_running_instances[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minute[0].arn
}

resource "aws_cloudwatch_metric_alarm" "running_instances_alarm" {
  count = var.use_autoscaling ? 0 : 1
  
  alarm_name          = "no-running-instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RunningInstances"
  namespace           = "Custom"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Triggers if no EC2 instances are running"

  alarm_actions = [aws_sns_topic.instance_count_alarm_topic[0].arn]
}
