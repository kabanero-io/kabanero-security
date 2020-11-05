#!/bin/bash

set -e

mkdir -p ./etc/yum.repos.d
cp -R /etc/yum.repos.d/* ./etc/yum.repos.d
echo "$DOCKER_PASSWORD" | podman login -u "$DOCKER_USERNAME" --password-stdin docker.io
podman build -t $DOCKER_ORG/scanner -t $DOCKER_ORG/scanner:latest .
podman push $DOCKER_ORG/scanner
