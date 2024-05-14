data "template_file" "setup-ec2-script" {
  template = file("setup-ec2.sh")
  vars = {
    COGNITO_CLIENT_ID = local.envs["COGNITO_CLIENT_ID"]
    FLASK_SECRET_KEY = local.envs["FLASK_SECRET_KEY"]
  }
}

resource "aws_instance" "cloudtictactoe_server" {
  ami           = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 on us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.cloudtictactoe_server_subnet1.id
  vpc_security_group_ids = [
    aws_security_group.cloudtictactoe_server_sg_http.id,
    aws_security_group.cloudtictactoe_server_sg_ssh.id
  ]
  associate_public_ip_address = true

  user_data = data.template_file.setup-ec2-script.rendered

  tags = {
    Name = "Cloud Tic Tac Toe Server Instance"
  }
}
