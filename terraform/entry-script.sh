#!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker 
sudo usermod -aG docker ec2-user

# install docker-compose 
sudo sudo yum install docker-compose-plugin -y
sudo chmod +x /usr/local/bin/docker-compose