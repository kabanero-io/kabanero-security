#!/bin/bash
# set namespace. the default is kabanero
NAMESPACE=kabanero

# set a signature storage location.
# this is used in order to store generated signatures for the images.
# thus write access by the pod user (non root) needs to be granted.
# if PersistentVolume is used, this value is not required.
#HOST_SIGNATURE_STORAGE_DIR="/var/tmp"
#HOST_SIGNATURE_STORAGE_DIR="/mnt/signtask"

# set an ID of secret key for signing. The same ID, which used for generating
# the keypair, should set.
SIGNER_NAME="security@example.com"

SIGNATURE_STORAGE_ROOT="/mnt/signtask"
SIGNATURE_STORAGE_DIR=$SIGNATURE_STORAGE_ROOT/sigstore
SOURCE_TRANSPORT="docker://"
SIGNED_TRANSPORT="docker://"

# extract the secret key and store as a k8s secret
echo "creating secret/signature-secret-key from ~/.gnupg/secring.gpg"
cat <<EOF | oc -n $NAMESPACE apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: signature-secret-key
data:
  secret.asc: $(gpg --export-secret-keys $SIGNER_NAME | base64 -w 0)
EOF
# get internal docker registry. this might not work for OpenShift v4.
REGISTRY_HOST=$(oc get image.config.openshift.io/cluster -o yaml|grep internalRegistryHostname|awk '{print $2}')
echo "Registry host : ${REGISTRY_HOST}"

if [ $REGISTRY_HOST ]; then
echo "Create default.yaml file which will be mounted in /etc/containers/registries.d"
cat <<EOF | oc -n $NAMESPACE apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: registry-d-default
data:
  default.yaml: |
    # This is a default registries.d configuration file.
    # This file may be modified in order to configure the location of look aside signature store.
    # Please refer to /etc/containers/registries.d/default.yaml file for more information.
    default-docker:
    # no default value in order to let skopeo push the signature to the internal docker registry.
    docker:
      docker.io:
        # the directory below may be shared disk in order to accessing the signature from any nodes.
        sigstore: file://$SIGNATURE_STORAGE_DIR
        sigstore-staging: file://$SIGNATURE_STORAGE_DIR
EOF

echo "Applying sign-task"
cat <<EOF | oc -n $NAMESPACE apply -f -
apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: sign-task
spec:
  inputs:
    resources:
      - name: source-image
        type: image
      - name: signed-image
        type: image
    params:
      - name: sign-by
        description: Name of the signing key.
        default: $SIGNER_NAME
  steps:
    - name: sign-image
      securityContext: {}
      image: $REGISTRY_HOST/kabanero/signer
      command: ['/bin/bash']
      args: ['-c', 'gpg --import /etc/gpg/secret.asc ; skopeo --debug copy --dest-tls-verify=false --src-tls-verify=false --remove-signatures --sign-by \$(inputs.params.sign-by) $SOURCE_TRANSPORT\$(inputs.resources.source-image.url) $SIGNED_TRANSPORT\$(inputs.resources.signed-image.url)']
      volumeMounts:
        - name: sign-secret-key
          mountPath: /etc/gpg
        - name: registries-d-dir
          mountPath: /etc/containers/registries.d
        - name: signature-storage
          mountPath: $SIGNATURE_STORAGE_ROOT
  volumes:
    - name: sign-secret-key
      secret:
        secretName: signature-secret-key
    - name: registries-d-dir
      configMap:
        name: registry-d-default  
    - name: signature-storage
      persistentVolumeClaim:
        claimName: signature-storage
##      hostPath:
##        path: $HOST_SIGNATURE_STORAGE_DIR
EOF

echo "Applying sign-pipeline"
cat <<EOF | oc -n $NAMESPACE apply -f -
apiVersion: tekton.dev/v1alpha1
kind: Pipeline
metadata:
  name: sign-pipeline
spec:
  resources:
    - name: source-image
      type: image
    - name: signed-image
      type: image
  tasks:
    - name: kabanero-sign
      taskRef:
        name: sign-task
      resources:
        inputs:
        - name: source-image
          resource: source-image
        - name: signed-image
          resource: signed-image
      params:
      - name: sign-by
        value: $SIGNER_NAME
EOF
fi
