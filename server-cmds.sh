#!/usr/bin/env bash

export IMAGE=$1
export DOCKER_USER=$2
export DOCKER_PWD=$3
echo $3 | docker login -u $2 --password-stdin
docker-compose -f docker-compose.yaml up --detach
echo "success"
