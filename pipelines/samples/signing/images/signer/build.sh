#!/bin/bash

set -e
namespace=kabanero
oc create configmap yum-repos-d --from-file /etc/yum.repos.d -n ${namespace} 
oc apply -f signer-bc.yaml -f signer-stream.yaml -n ${namespace}
oc start-build signer --from-file=Dockerfile --follow -n ${namespace}
oc delete configmap yum-repos-d -n ${namespace}
