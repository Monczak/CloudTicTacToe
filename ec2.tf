data "external" "get_credentials" {
  program = ["bash", "${path.module}/get-credentials.sh"]
}

data "template_file" "setup-ec2-script" {
  template = file("setup-ec2.sh")
  vars = {
    COGNITO_CLIENT_ID = aws_cognito_user_pool_client.cloudtictactoe_cognito_client.id
    FLASK_SECRET_KEY  = local.envs["FLASK_SECRET_KEY"]
    DB_USERNAME       = local.envs["DB_USERNAME"]
    DB_PASSWORD       = local.envs["DB_PASSWORD"]
    DB_ENDPOINT       = aws_db_instance.cloudtictactoe_db.endpoint
    AWS_ACCESS_KEY    = data.external.get_credentials.result.access_key
    AWS_SECRET_KEY    = data.external.get_credentials.result.secret_key
    AWS_SESSION_TOKEN = data.external.get_credentials.result.session_token
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

  depends_on = [aws_db_instance.cloudtictactoe_db]
}