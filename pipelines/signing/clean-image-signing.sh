#!/bin/bash
#set namespace
NAMESPACE=kabanero

oc -n ${NAMESPACE} delete PipelineResource/sample-source-image
oc -n ${NAMESPACE} delete PipelineResource/sample-signed-image
oc -n ${NAMESPACE} delete PipelineRun/sample-signing--pipeline-run
oc -n ${NAMESPACE} delete Task/sign-task
oc -n ${NAMESPACE} delete Pipeline/sign-pipeline
oc -n ${NAMESPACE} delete configmap/registries-d
oc -n ${NAMESPACE} delete secret/image-signing-config

