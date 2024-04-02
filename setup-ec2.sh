#!/bin/bash

# Install Docker and Git
yum update -y
yum install -y docker git

# Start Docker daemon
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repo
git clone --recurse-submodules https://github.com/Monczak/cloudtictactoe /cloudtictactoe

# Setup systemd service to run project on instance reboot
cp /cloudtictactoe/cloudtictactoe.service /etc/systemd/system/cloudtictactoe.service
chmod 644 /etc/systemd/system/cloudtictactoe.service
systemctl enable cloudtictactoe

# Build images and run project
/usr/local/bin/docker-compose -f /cloudtictactoe/docker-compose.yml up -d
