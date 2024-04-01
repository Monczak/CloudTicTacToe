#!/bin/bash

sudo yum update -y
sudo yum install -y docker

sudo systemctl enable docker
sudo systemctl start docker

sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

git clone --recurse-submodules https://github.com/Monczak/cloudtictactoe ~/cloudtictactoe
cd ~/cloudtictactoe
sudo /usr/local/bin/docker-compose up -d # Shouldn't need to use sudo here
