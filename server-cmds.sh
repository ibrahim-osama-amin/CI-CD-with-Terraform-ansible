#!/usr/bin/env bash

echo "Setting Environmental variables"

DOCKER_USER="$1"
DOCKER_PWD="$2"

echo "logging into docker"
echo "$DOCKER_PWD" | sudo docker login -u "$DOCKER_USER" --password-stdin

echo "Starting docker compose now"
sudo docker-compose -f docker-compose.yaml --env-file docker-compose.env up --detach
echo "success"
