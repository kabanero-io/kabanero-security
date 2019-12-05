#!/bin/bash

set -Eeuox pipefail

### Configuration ###

# An image to be signed #
SOURCE_IMAGE="${SOURCE_IMAGE:-docker.io/httpd}"
# A signed image #
SIGNED_IMAGE="${SIGNED_IMAGE:-image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd}"

### Tekton Example ###
NAMESPACE=kabanero
NAMESPACE_SIGNED=kabanero-signed

# Cleanup
oc -n ${NAMESPACE} delete pipelinerun image-signing-manual-pipeline-run || true

# Create a namespace to store the signed image
oc get namespace kabanero-signed
if [ $?  -ne 0 ]
then
echo "Creating namespace $NAMESPACE_SIGNED}"
oc create namespace ${NAMESPACE_SIGNED}
fi

# Pipeline Resources: Source and signed container image
cat <<EOF | oc -n ${NAMESPACE} apply -f -
apiVersion: v1
items:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: source-image-sample
  spec:
    params:
    - name: url
      value: ${SOURCE_IMAGE}
    type: image
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: signed-image-sample
  spec:
    params:
    - name: url
      value: ${SIGNED_IMAGE}
    type: image
kind: List
EOF

# Manual Pipeline Run
cat <<EOF | oc -n ${NAMESPACE} apply -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  name: image-signing-manual-pipeline-run
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: sign-pipeline
  resources:
  - name: source-image
    resourceRef:
      name: source-image-sample
  - name: signed-image
    resourceRef:
      name: signed-image-sample
  serviceAccount: kabanero-operator
  timeout: 60m
EOF
