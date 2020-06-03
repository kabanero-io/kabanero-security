# Welcome to the Kabanero look aside signature server and related files.

# Table of Contents
1. [About Look aside signature server](#About-look-aside-signature-server)
1. [Prerequisite](#Prerequisite)
1. [Build](#Build)
    1. [Copy kabanero-security Git repository](#Copy-kabanero-security-Git-repository)
    1. [Building the images](#Building-the-images)
1. [Deploy](#Deploy) 
1. [Configuration](#Configuration) 
    1. [Signature data backup](#Signature-data-backup)
    1. [Persistent storage](#Persistent-storage)
1. [Accessing the server](#Accessing-the-server)
    1. [Storing signatures](#Storing-signatures)
    1. [Getting signatures](#Getting-signatures)


# About look aside signature server
This server can be used as an augmenting server for any existing image registry to support the image signing and verification which is defined by [signature data](https://github.com/containers/image/blob/master/docs/containers-signature.5.md) and [access protocol](https://github.com/containers/image/blob/master/docs/signature-protocols.md). 

This server is not designed for the production environment, but for development and evaluation purposes.
In order to provide zero configuration experience, it uses a k8s secret as a backup storage, thus the maximum number of signatures which can be stored is about 500. 
In order to secure the data, it is recommended to use a persistent storage for storing the signatures.

This server consists of three container images.
* **initialize server** - The image for initializing the pod. It restores the back up data from the k8s secret named `signature-data`
* **signature server** - The image of the signature server which is a PHP server with apache http server. It is a simple http server which takes signatures by PUT request and returns signatures by GET request. When, a new signature is stored, it creates a zip file which contains entire signature storage and places the zip data to teh secret `signature-data` in a namespace where this server is deployed.
* **oauth proxy** - The OpenShift oauth proxy server which protects PUT requests by enforcing RBAC.
The PUT request is granted if an account is allowed creating secret resource.   

# Prerequisite

This sample uses ImageStream of OpenShift, therefore OpenShift CLI environment of OpenShift Cluster 4.x is required. And all of instruction is described by using oc commands. 

# Build
## Copy kabanero-security Git repository

After [download signature-server-v0.1.zip](https://github.com/kabanero-io/kabanero-security/releases/download/v0.1/signature-server-v0.1.zip) and unzip the file, or [clone](https://github.com/kabanero-io/kabanero-security.git) the repository, change the current directory to `signature-server`.

## Building the images

Since the build is done by the image stream on OpenShift, login to a cluster prior to run the build script.

(example)
```
oc login -u admin -p security https://openshift.my.com:8443/
```

Run the `sample/image/build.sh` to build two servers. 

The build creates the image in kabanero-security namespace and push the image to the OCP internal image registry. Note that the namespace can be changed by modifying `sample/image/build.sh`.

Verify the servers have been created as ImageStream.

(example output)
```
[admin@openshift imagestream]# oc get is -n kabanero-security
NAME                     IMAGE REPOSITORY                                                                            TAGS     UPDATED
signatures-init-server   image-registry.openshift-image-registry.svc:5000/kabanero-security/signatures-init-server   latest   3 minutes ago
signatures-server        image-registry.openshift-image-registry.svc:5000/kabanero-security/signatures-server        latest   2 minutes ago
```

# Deploy
Deploy a pod which hosts the images for the look aside signature server with required resources.

```
oc apply -n kabanero-security -f signature-server/sample/deploy/signature-server-combined.yaml
```
(example output)
```
[admin@openshift deploy]# oc apply -n kabanero-security -f signature-server/sample/deploy/signature-server-combined.yaml
configmap/signature-server-config created
serviceaccount/signature-server created
clusterrole.rbac.authorization.k8s.io/signature-server created
clusterrolebinding.rbac.authorization.k8s.io/signature-server created
route.route.openshift.io/signature-server created
service/signature-server created
deployment.apps/signature-server created
```

Verify that the pod is up and running
```
oc get pod -n kabanero-security
```
(example output)
```
[admin@openshift deploy]# oc get pod -n kabanero-security
NAME                                 READY   STATUS      RESTARTS   AGE
signature-init-server-1-build       0/1     Completed   0          10m
signature-server-1-build            0/1     Completed   0          8m24s
signature-server-5549cfd69b-mq8hc   2/2     Running     0          98s
```
# Configuration

There is not any configuration prior to use the server.However, it is recommended to use a persistent storage for preventing a potential of data loss.

## Signature data backup
By default, the look aside signature server does not require any persistent storage, instead, it stores the whole signature data to a secret resource named `signature-data`, in this secret, the zipped data is stored as `stored.zip` file.
This file is restored during the initialization when a pod which contains the look aside signature store server is started.

## Persistent storage 
In order to use persistent storage, mount any persistent storage to `/var/www/sigstore/html/signatures/`. The original configuration mounts an emptyDir.
At the same time, set `sigstore-save-secret` data in `signature-server-config' config map as `false` in order to disable storing the signatures as a secret.


# Accessing the server

## Storing signatures
To store a signature, a HTTP PUT method is used. The target URI is the form

> `/staging/`_registry_`/`_namespaces_`/`_name_`@`_digest-algo_`=`_digest-value_`/signature-`_index_

The target is protected by OpenShift OAuth proxy. A bearer token is required to authenticate and authorize requests. The token needs to be granted to store ImageSignature. Following shows the  required role.
```
- apiGroups:
  - ''
  - image.openshift.io
  resources:
    - imagesignatures
  verbs:
    - create
    - delete
```

For Kabanero either using kabanero-operator service account or use image-signer sample service account which is available in this repository.

The following shows an example by using curl when a signature of which name is signature-1 is for the image `mynamespace/busybox@sha256:817a12c32a39bbe394944ba49de563e085f1d3c5266eb8e9723256bc4448680e` which is stored in a registry `registry.example.com:5000` and a url of a look aside signature store is `signatures-server-icp4app-security.apps.myocp.example.com`
You need to modify existing Tekton tasks to add the code to put a generated signature to the signature server. 
```
TOKEN=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`

curl -X PUT -H "Authorization: Bearer $TOKEN" -T "@signature-1" https://signatures-server-icp4app-security.apps.myocp.example.com/signatures/registry.example.com=5000/mynamespace/busybox@sha256=817a12c32a39bbe394944ba49de563e085f1d3c5266eb8e9723256bc4448680e/signature-1
```

When a signature stored without any error, HTTP response code 201 is returned along with a text. Otherwise it returns HTTP response code other than 201.

The expected error codes include:

* _302_ - Authorization error
* _400_ - invalid path
* _507_ - failiure while storing a signature
Other error codes might be returned by oauth server, http server or php server.

Example of success case:

`Result:Success: stored to secret`


## Getting signatures

Signatures are accessed by HTTP GET method using URLs of the form. This is done by the application which supports the image verification. The target is not protected, so as far as the a signature is available for the specified URL, the contents are returned.

> `/signatures/`_registry_`/`_namespaces_`/`_name_`@`_digest-algo_`=`_digest-value_`/signature-`_index_

where _registry_ is the container image registry hostname and port. _=_ is used as a delimitor between host and port. (i.e., registry.example.com=5000). The rest of the values are documented [here](https://github.com/containers/image/blob/master/docs/signature-protocols.md#path-structure).
For example, if an image is available as `mynamespace/busybox@sha256:817a12c32a39bbe394944ba49de563e085f1d3c5266eb8e9723256bc4448680e` which is stored in a registry `registry.example.com:5000` and a url of a look aside signature store is `signatures-server-icp4app-security.apps.myocp.example.com`, the URL is

`https://signatures-server-icp4app-security.apps.myocp.example.com/signatures/registry.example.com=5000/mynamespace/busybox@sha256=817a12c32a39bbe394944ba49de563e085f1d3c5266eb8e9723256bc4448680e/signature-1`

The target root URL need to be placed in a specific docker configuration file. Please refer to [this documentation](https://github.com/containers/image/blob/master/docs/containers-registries.d.5.md)
For example, if the target image registry is `registry.example.com:5000` and a url of a look aside signature store is `signatures-server-icp4app-security.apps.myocp.example.com`, the file need to have the following entry. Also make sure `/etc/containers/policy.json` file is configured to set the public key which is used for verification.

```
docker:
    registry.example.com:5000:
        sigstore: https://signatures-server-icp4app-security.apps.myocp.example.com/signatures/registry.example.com=5000
```

#### Signature data backup
By default, the look aside signature store server does not require any persistent storage, instead, it stores the whole signature data to a secret resource named _signature-data_, in this secret, the zipped data is stored as _stored.zip_ file.
This file is restored during the initialization when a pod which contains the look aside signature store servr is started.
