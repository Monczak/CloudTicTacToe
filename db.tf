resource "aws_db_subnet_group" "cloudtictactoe_db_subnet_group" {
  name = "main"
  subnet_ids = [aws_subnet.cloudtictactoe_server_subnet1.id, aws_subnet.cloudtictactoe_server_subnet2.id]
}

resource "aws_security_group" "cloudtictactoe_sg_internal" {
  vpc_id = aws_vpc.cloudtictactoe_server_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "cloudtictactoe_db" {
  db_name = "main"
  allocated_storage = 10
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  username = local.envs["DB_USERNAME"]
  password = local.envs["DB_PASSWORD"]

  db_subnet_group_name = aws_db_subnet_group.cloudtictactoe_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.cloudtictactoe_sg_internal.id]
  
  skip_final_snapshot = true
}