#!/bin/bash

set -e

oc create configmap yum-repos-d --from-file /etc/yum.repos.d 
oc apply -f scanner-bc.yaml -f scanner-stream.yaml
oc start-build scanner --from-file=Dockerfile --follow
oc delete configmap yum-repos-d
#echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
#docker push $DOCKER_ORG/scanner
