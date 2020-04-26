#!/bin/bash
#set namespace, signby and registry
namespace=kabanero
signby=security@example.com
registry=image-registry.openshift-image-registry.svc:5000/kabanero-signed

cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: image-signing-config
data:
  secret.asc: $(gpg -a --export-secret-keys ${signby} | base64 -w 0)
  registry: $(echo $registry | base64 -w 0)
EOF
