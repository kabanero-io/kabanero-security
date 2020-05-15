#!/bin/bash

set -e
NAMESPACE=$1

BASE_DIR="$(cd $(dirname $0) && pwd)"
cd $BASE_DIR
oc apply -f init-server-bc.yaml -f init-server-stream.yaml -n $NAMESPACE
oc start-build signature-init-server --from-file=Dockerfile --follow -n $NAMESPACE
