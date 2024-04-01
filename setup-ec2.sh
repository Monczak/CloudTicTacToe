#!/bin/bash

sudo apt update -y
sudo apt install -y docker

sudo systemctl enable docker
sudo systemctl start docker

sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

git clone --recurse-submodules https://github.com/Monczak/cloudtictactoe ~/cloudtictactoe
cd ~/cloudtictactoe
git submodule update --init --recursive --remote

/usr/local/bin/docker-compose up -d
