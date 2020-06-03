#!/bin/bash

set -e
NAMESPACE=$1
BASE_DIR="$(cd $(dirname $0) && pwd)"
echo $BASE_DIR
cd $BASE_DIR

oc delete configmap phpfile -n $NAMESPACE | true
oc create configmap phpfile --from-file store.php -n $NAMESPACE
oc apply -f signature-server-bc.yaml -f signature-server-stream.yaml -n $NAMESPACE
oc start-build signature-server --from-file=Dockerfile --follow -n $NAMESPACE
oc delete configmap phpfile -n $NAMESPACE
