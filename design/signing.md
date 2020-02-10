# Kabanero Security Container Signing

## Key Concepts / Background
- As part of the devsecops story for Kabanero, we need to offer an out of the box container signing task in the build pipeline.

[High level overview](../design/Kabanero_scan_sign.pdf)

## User stories
- As Champ (architect), I would like to be able to ensure that application containers are signed when they are deployed/saved in a container registy.

## As-is

- There is no default container signing in the Kabanero Tekton pipeline

## To-be
- When a Kabanero instance is installed, regardless of the runtime stack in use, there is a Skopeo-based container signing task enabled in the Tekton pipeline

## Main Feature design

- The following are the steps we will automate in order to enable container signing in the Kabanero pipeline:
### Build:
#### 1) Download and build an Skopeo signing image:
See: https://github.com/containers/skopeo

#### 2)Upload the image to DockerHub (in kabanero/signing) - these steps are required as part of Kabanero build

### Done as part of Kabanero pipelines impl:

#### 3) Generate RSA keypair for signing and set the generate private key as a secret. It is consumed by skopeo while signing the image.

#### 4) Update sign task to configure the signature store location if the signed image is stored other than the Openshift internal image registry.

#### 5) Update sign-pipeline.yaml to include the pipeline task for signing.

```
   resources:
   - name: source-image
   type: image
   - name: signed-image
   type: image
   tasks:
   - name: kabanero-sign
   params:
   - name: sign-by
   value: security@example.com
```

Note that the value of sign-by corresponds to the email address of the generated keypair.

#### 6) Signature store
When the image repository of the signed image is the Openshift internal image registry, the generated signature is stored into the same registry.  Otherwise, the signature is stored in the location that was configured by the signing task.

We need to automate the creation of the keypair for signing by the sample image signing operator.

### Issues closed on this to date:
https://github.com/kabanero-io/kabanero-security/issues/51  Provide automated RSA Key pair generation for image signing


## Discussion:  
Follow-on work:
https://github.com/kabanero-io/kabanero-security/issues/61   Container image signature support - Phase 3

- Provide a secure lookaside signature store for supporting external image stores. Ideally some standalone repository which is accessible by a REST API.
- Automate updating the node configuration for enabling image verification.

