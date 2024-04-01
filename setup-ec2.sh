#!/bin/bash

echo Test
echo $(pwd)
echo Test > /home/ec2-user/test.txt

yum update -y
yum install -y docker git

systemctl enable docker
systemctl start docker

curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

git clone --recurse-submodules https://github.com/Monczak/cloudtictactoe /cloudtictactoe
cd /cloudtictactoe
/usr/local/bin/docker-compose up -d
