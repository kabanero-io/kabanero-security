#!/bin/bash
NAMESPACE=kabanero-security
#  Create a namespace to store the signed image
oc get namespace $NAMESPACE
if [ $? -ne 0 ]; then
  echo "Creating namespace $NAMESPACE"
  oc create namespace $NAMESPACE
fi
BASE_DIR="$(cd $(dirname $0) && pwd)"
cd $BASE_DIR
echo "Building signature-init-server"
init-server/build.sh $NAMESPACE
if [ $? -ne 0 ]; then
exit 1
fi
echo "Building signature-server"
server/build.sh $NAMESPACE
