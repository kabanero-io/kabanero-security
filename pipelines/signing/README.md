# Kabanero Container Image Signing 
The kabanero-security repository contains sample tasks, and pipelines for signing container images built in the Kabanero pipeline. Container image signing is embedded some of the kabanero pipelines which push an image to an image registry. By default, the container image signing is not enabled. To enable image signing, review the following instructions.

# About container image signing and verification
There are several variations to assure the integrity and authenticity of the container image. Kabanero image signing follows [this standard](https://github.com/containers/image/blob/master/docs/containers-signature.5.md) which can be used for both Openshift internal image registry and external image registries.
The container tool such as cri-o, podman or docker are capable to compute the signature of an image and prevent pulling the image into it's local registry unless the signature value matches with the original image signature value. With this functionality, it can prevent deploying un-trusted or potentially altered images in the system.

# Prerequisites

## Container image for image signing

Kabanero-security uses [skopeo](https://github.com/containers/skopeo) for the container image signing.
Therefore, it is required to use a container image which skopeo is available. The kabanero-pipelines are used to use [kabanero/kabanero-utils](https://hub.docker.com/r/kabanero/kabanero-utils) container image, also the same iange is used in the standaline image siging task example in this document.

The first step is to create an image which is responsible to access the original image, compute signature value, then store signed image and it's signature as one of tasks of the pipeline.

## Kabanero pipelines

This document assumes that there is a cluster environment where [Kabanero pipelines](https://github.com/kabanero-io/kabanero-pipelines) are installed.

# Configuration

The following configuration steps are required:

1. **Generate a key pair** - In order to sing images, a RSA key pair is required. A secret key is used for signing images, and a corresponding public key is used for verifying signed images. In here, only the secret key is used since signed image verification is out of this document.
1. **Create a secret** - A Kubernetes secret contains the generated RSA secret and several configuration parameters.
1. **Create a configmap** - A Kubernetes configmap contains several configuration parameters.

## Generate a key pair
### Create a batch file for generating a key pair for signing

Create a file named gpg-batch and copy and paste the following contents. Make sure that Name-Real, Name-Comment, and Name-Email are modified as you like.

```
%echo Generating a default key
Key-Type: RSA
Key-Length: 2048
Name-Real: <Owner name i.e., John Do>
Name-Comment: <Any comment i.e., Signing key for kabanero>
Name-Email: <e-mail address which is used as an id of the key  i.e., security@example.com>
Expire-Date: 0 
%commit
%echo done
``` 
### generate a key pair

If it is the first time to generate a key pair, rng-tools needs to be installed in order to generate some seed for random value.
```
yum install rng-tools
rngd -r /dev/urandom
```

Run the following command for generating PGP key pair. If the passphrase input panel is displayed, press enter without setting a passphrase on for disabling the passphrase key encryption.
```
gpg --batch --gen-key gpg-batch
```
Once the key is generated, extract the public key and store it to a safe place for now. The public key is required for verifying the signature.
```
gpg --armor --export --output signingkey.pub <Name-Email which was used for generating the key pair>
```

## Create a secret

A following secret named `image-signing-config` needs to be created to set the generated RSA secret key, the registry location where signed images are stored. A sample script is provided.

```
apiVersion: v1
kind: Secret
metadata:
  name: image-signing-config
data:
  secret.asc: <armerd secret key>
  registry: <registry name where the signed image is stored. i.e., >
```

Modify the first few lines of `create-secret.sh` file for your environment and run the script. Make sure that you have logged in the cluster environment. This script extracts the generated RSA secret then create and apply a secret as configured. The following is an example values of the script:
```
#!/bin/bash
#set namespace, signby and registry
namespace=kabanero
signby=security@example.com
registry=image-registry.openshift-image-registry.svc:5000/kabanero-signed
:
:
``` 

## Create a configmap

A following configmap named `registries-d` needs to be created to set the location where generated signatures are stored. This configuration is for the OpenShift internal image registry which supports storing the signatures by using the REST API.

```
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
```
As an example, `create-configmap.sh` is provided. Apply this file as it is if OpenShift internal image registry or an image registry which is capable of storing signatures. 

Note that when the external image registry which does not support storing the signature, this configmap needs to be modified to set a persistent storage location where the signatures are stored. [This document](https://github.com/containers/image/blob/master/docs/containers-registries.d.5.md) describes how to configure registries-d file. Additionally, it might require modifying a pipeline task to mount a persistent storage to extract generated signatures.



# Use stand-alone image signing pipeline

A stand-alone image signing pipeline is provided as `image-signing-pipeline.yaml` which consists of sign-task and sign-pipeline. This pipeline takes two parameters as follows:

* **source-image** - a source image name. i.e., docker.io/httpd.
* **signed-image** - a signed image name. the namespace (project) name needs to match with the namespace of registry name in image-signing-config secret. i.e., image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd

## Sample image signing pipeline run

There is a sample script which deploys `image-signing-pipeline.yaml` and starts a sign pipeline run which pulls the latest httpd image from docker.io, sign the image, and push the image to kabanero-signed/http in the OpenShift internal image registry. This script creates kabanero-signed project for storing a signed image. After configuring a secret and configmap by running `create-secret.sh` and `create-configmap.sh`,  review and run `sample-image-signing-pipeline-run.sh`.
You can review the progress of the pipeline run in the tekton dashboard.

## Clean up the sample resources

`clean-image-signing.sh` is provided for delete all of resources of the image signing which were created in this documentation.

# Use image signing task from kabanero pipelines

Once `image-signing-config` secret and `registries-d` configmap are created, the kabanero pipelines which run one of following tasks will sign images when an image is pushed to the image registry.

* build-deploy-task
* build-push-jk-task
* build-push-task


# Use image signing task from your pipeline

`image-signing-pipeline.yaml`, which consists of sign-task and sign-pipeline, can be used as a template for integrating the image sign task to your pipelines.

# Verifying signatures

Refer to the [this document](https://developers.redhat.com/blog/2019/10/29/verifying-signatures-of-red-hat-container-images/) for verifying images with signatures.
