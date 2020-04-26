#!/bin/bash
#set namespace
namespace=kabanero

cat <<EOF | oc -n ${namespace} apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: registries-d
data:
  default.yaml: |-
    # This is a default registries.d configuration file.
    # This file may be modified in order to configure the location of look aside signature store.
    # Please refer to /etc/containers/registries.d/default.yaml file for more information.
    default-docker:
    # no default value in order to let skopeo push the signature to the internal docker registry.
EOF
