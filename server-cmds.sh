#!/usr/bin/env bash

echo "Setting Environmental variables"

export IMAGE=$1
export DOCKER_USER=$2
export DOCKER_PWD='$3'

echo "logging into docker"
echo $DOCKER_PWD | sudo docker login -u $DOCKER_USER --password-stdin

echo "Starting docker compose now"
sudo docker-compose -f docker-compose.yaml up --detach
echo "success"
