#!/bin/bash

set -Eeuox pipefail

### Configuration ###
# An image to be signed #
SOURCE_IMAGE="${SOURCE_IMAGE:-docker.io/httpd}"
# A signed image #
SIGNED_IMAGE="${SIGNED_IMAGE:-image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd}"
# namespace/project where a pipeline runes
NAMESPACE=kabanero
# namespace/project where a generated image is stored
NAMESPACE_SIGNED=kabanero-signed

# Cleanup
oc -n ${NAMESPACE} delete pipelinerun sample-signing--pipeline-run || true

# Create a namespace to store the signed image
echo "Creating namespace ${NAMESPACE_SIGNED}"
oc create namespace ${NAMESPACE_SIGNED} || true

oc -n ${NAMESPACE} apply -f image-signing-pipeline.yaml

# Pipeline Resources: Source and signed container image
cat <<EOF | oc -n ${NAMESPACE} apply -f -
apiVersion: v1
items:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: sample-source-image
  spec:
    params:
    - name: url
      value: ${SOURCE_IMAGE}
    type: image
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: sample-signed-image
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
  name: sample-signing--pipeline-run
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: sign-pipeline
  resources:
  - name: source-image
    resourceRef:
      name: sample-source-image
  - name: signed-image
    resourceRef:
      name: sample-signed-image
  serviceAccountName: kabanero-operator
  timeout: 60m
EOF

