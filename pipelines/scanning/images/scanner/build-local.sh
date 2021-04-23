#!/bin/bash

# To build locally on RHEL 8 or Centos 8 machine
# Prerequisites: podman, and git
export DOCKER_ORG=icp4apps
rm -rf ./etc
mkdir -p ./etc
cp -R /etc/yum.repos.d ./etc
mkdir -p ./etc/pki
cp -R /etc/pki/rpm-gpg ./etc/pki
podman build  -f Dockerfile.local -t $DOCKER_ORG/scanner:latest .
