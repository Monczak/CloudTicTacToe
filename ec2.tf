data "template_file" "setup-ec2-script" {
  template = file("setup-ec2.sh")
  vars = {
    COGNITO_CLIENT_ID = aws_cognito_user_pool_client.cloudtictactoe_cognito_client.id
    FLASK_SECRET_KEY  = local.envs["FLASK_SECRET_KEY"]
  }
}

resource "aws_instance" "cloudtictactoe_server" {
  count = var.use_autoscaling ? 0 : 1

  ami           = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 on us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.cloudtictactoe_server_subnet1.id
  vpc_security_group_ids = [
    aws_security_group.cloudtictactoe_server_sg_http.id,
    aws_security_group.cloudtictactoe_server_sg_ssh.id
  ]
  associate_public_ip_address = true

  user_data = data.template_file.setup-ec2-script.rendered

  monitoring = true

  tags = {
    Name = "Cloud Tic Tac Toe Server Instance"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = "LabRole"
}