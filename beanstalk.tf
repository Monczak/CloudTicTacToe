resource "aws_elastic_beanstalk_application" "cloudtictactoe_app" {
  name        = "Cloud Tic Tac Toe"
  description = "Cloud Tic Tac Toe Application"
}

resource "aws_elastic_beanstalk_application_version" "cloudtictactoe_app_version" {
  name        = "v1.0.0"
  description = "Cloud Tic Tac Toe Application Version 1.0.0"
  application = aws_elastic_beanstalk_application.cloudtictactoe_app.name

  bucket = aws_s3_bucket.cloudtictactoe_server_bucket.id
  key    = aws_s3_object.cloudtictactoe_server_source_bundle.id
}

resource "aws_elastic_beanstalk_environment" "cloudtictactoe_env" {
  name                = "cloudtictactoe-env"
  application         = aws_elastic_beanstalk_application.cloudtictactoe_app.name
  version_label       = aws_elastic_beanstalk_application_version.cloudtictactoe_app_version.name
  solution_stack_name = "64bit Amazon Linux 2 v3.8.0 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.cloudtictactoe_server_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.cloudtictactoe_server_subnet1.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = aws_subnet.cloudtictactoe_server_subnet1.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internetFacing"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.cloudtictactoe_server_sg_http.id},${aws_security_group.cloudtictactoe_server_sg_ssh.id}"
  }

  setting {
    namespace = "aws:elb:listener:80"
    name      = "ListenerProtocol"
    value     = "TCP"
  }

  setting {
    namespace = "aws:elb:listener:80"
    name      = "InstanceProtocol"
    value     = "TCP"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  tags = {
    Name = "Cloud Tic Tac Toe EB Environment"
  }
}