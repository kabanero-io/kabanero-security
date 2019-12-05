# Sample image signing 
The kabanero-security repository contains sample tasks, pipelines, and images for signing images built in the Kabanero pipeline.

# About image signature signing and verification
There is a standard to compute the signature of the image and the format of the signature. This standard can be used for authenticity of the image in the public and private image registiries.
The container tool such as podman or docker is capable to compute the signature of an image and prevent pulling the image into it's local registry unless the signature value matches with the original image signature value. With this functionality, it can prevent deploying untrusted or potentially altered images in the system. This functionality is disabled by default. 

This sample provides the steps to sign the image and store it's signature as a part of tekton pipeline, and also steps to verify the signature by using podman on OCP.

# Building the sample image for signing

The first step is to create an image which is responsible to access the original image, compute signature value, then store signed image and it's signature as one of tasks of the pipeline.

## Clone the sample into the local machine
In this sample, it is assumed that all tasks is done on the machine which the following packages are installed:
yum, git, gpg.

Run following command.
```
git clone https://github.com/kabanero-io/kabanero-security.git
```

## Build the Kabanero signer image
1. Login to your cluster with an ID which can access kabanero namespace.
2. Run the following commands
```
cd ./kabanero-security/pipelines/signing/images/signer
./build.sh
```

The build creates the image in kanabero namespace and push the image to the OCP internal image registry.
```
image-registry.openshift-image-registry.svc:5000/kabanero/signer
```

## Configure the signing-pipeline and task

In order to sign the image, a RSA keypair needs to be generated and configure the genererated secret key as a secret in OCP.

### create a batch file for generating keypair for signing
Create a file named gpg-batch and copy and paste the following contents. Make sure thant Name-Real, Name-Comment, and Name-Email are modified as you like.

```
%echo Generating a default key
Key-Type: RSA
Key-Length: 2048
Name-Real: <Owner name i.e., John Do>
Name-Comment: <Any comment i.e., Signing key for kabanero>
Name-Email: <e-mail address which is used as an id of the key  i.e., security@example.com>>
Expire-Date: 0 
%commit
%echo done
``` 
### generate a keypair
If it is the first time to generate a keypair, rng-tools needs to be installed in order to generate some seed for random value.
```
yum install rng-tools
rngd -r /dev/urandom
```

Run the following command for generating PGP keypair.
```
gpg --batch --gen-key gpg-batch
```
Once the key is generated, extract the public key and store it to a safe place for now. The public key is required for verifying the signature.
```
gpg --armor --export --output signingkey.pub <Name-Email i.e., security@example.com>
```
### configure a script file for pipeline and task
Modify a few lines of create-resources-for-signing-4.sh file as follows:
```
# set namespace. the default is kabanero
NAMESPACE=kabanero

# set a signature registry location.
# This is used in order to store generated signatures for the images.
# a shared disk among nodes is recommended. or you might need to manually
# synchornize the contents among nodes for validating the signature by OCP.
# the default location is /var/lib/atomic/sigstore
# If you are planning to store the signed images into the internal image registry, 
# leave it as it is.
HOST_SIGNATURE_REGISTRY_DIR="/var/lib/atomic/sigstore"

# set an ID of secret key for signing. The same ID, which used for generating
# the keypair, should set.
SIGNER_NAME="security@example.com"
```

### run the script which extract the generated secret key then store them as a k8s secret. after that, create a sample pipeline and task for signing.
in order to browse the contents of pipeline and task, run following command.
```
./create-resources-for-signing-4.sh
```
The expected output is
```
creating secret/signature-secret-key from ~/.gnupg/secring.gpg
secret/signature-secret-key created
Registry host : image-registry.openshift-image-registry.svc:5000
Applying registry certificate for signing work.
configmap/registry-cert configured
Create default.yaml file which will be mounted in /etc/containers/registries.d
configmap/registry-d-default configured
Applying sign-task
task.tekton.dev/sign-task configured
Applying sign-pipeline
pipeline.tekton.dev/sign-pipeline configured
```

## Use the sign-task from your pipeline

The sample sign task and pipeline are applied by create-resources-for-signing-4.sh script. the contents of the sample task and pipeline can be browse by the following commands. These information can be integrated into your pipeline.

Browse sample pipeline
```
oc -n kabanero get pipeline.tekton.dev/sign-pipeline -o yaml
```
Browse sample signing task
```
oc -n kabanero get task.tekton.dev/sign-task -o yaml
```

## Create the PipelineResource

Ensure that a PipelineResource containing the image (docker) repositories information for the location of source image and signed image are created before running the pipeline. Following is the sample yaml file for creating the resources:
```
apiVersion: v1
items:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: source-image
  spec:
    params:
    - name: url
      value: docker.io/httpd:latest
    type: image
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: signed-image
  spec:
    params:
    - name: url
      value: image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd:latest
    type: image
kind: List

```

## Run the pipeline

Sample PipelineRun file is provided under ./pipelines/signing. This sample is pulling the httpd image from docker.io, sign the image, then store it into local image registry as mage-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd:latest
```
./sample-signing-pipeline-run.sh
```

## Check the status of the pipeline run

```
oc -n kabanero describe pipelinerun.tekton.dev/image-signing-manual-pipeline-run
```

## Execute pipelines using the Tekton Dashboard

You can also login to the Tekton Dashboard and create a new pipeline run to execute the pipeline that uses the sign-task Task.

## Storing signatures

The generated signatures are stored various locations based on the capability of the image reegistry.
The internal image registry (image-registry.openshift-image-registry.svc:5000) is capable to store the signatures as a part of metadata in the registry. Therefore the signatures are not stored locally.
The external registries such as docker.io are not supporting the same mechanism as the internal image registry supports, thus the signatures are stored locally. The location is set by the task. The default location is /var/lib/atomic/sigstore of the node where the sign task ran. 
Since it is likely that a node which sign task ran and a node to verify the signature are different, if there is a plan to verify the signed image, it is recommended to mount a shard disk to each node in order to store the generated signature in the shared location among nodes.

## Verifying signatures

Plese refer to the following document for verifying the signature.

https://developers.redhat.com/blog/2019/10/29/verifying-signatures-of-red-hat-container-images/

# Step by step instructions for end to end scenario

The following is the sample of steps for signing and verifying the image.
The scenario here is as follows:
1. configure the system for signing and verifying the image. In here, kabanero-signed namespace is used for verifying the image. This means that unless an image signature matches the computed signature from the image, the image cannot be pulled by podman.
2. make sure that signature verification is configured properly. In here, pull unsigned httpd image from docker.io and push it to the internal image registry, then try to pull it. This pull will fail because the image does not have a signature.
3. run a signing pipeline for signing the image. In here, httpd image on docker.io is used for signing and once the image is signed, it'll be stored in the internal image registry. In this case, the generated signature is also stored in the registry.
4. make sure that signed image can be pulled.

## 1. Configure the system
### 1.1. Build the Kabanero signer image
Login to your cluster with an cluster admin id.
Run the following commands
```
cd ./kabanero-security/pipelines/signing/images/signer
./build.sh
```

### 1.2. Generating a keypair
Move the current directory.
```
cd ./kabanero-security/pipelines/signing/sample-scenario
```
Install rng-tools
```
yum install rng-tools
rngd -r /dev/urandom
```

Run the following command for generating PGP keypair. This command create a keypair with ID security@example.com
```
gpg --batch --gen-key sample-gpg-batch
```
Once the key is generated, verify that only one key of which id is security@example.com
```
gpg --list-secret-keys
```

Extract the public key and store it. The public key is required for verifying the signature.
```
gpg --armor --export --output signingkey.pub security@example.com
```
### 1.3. Configure a secret, task and pipeline.
Run following command.
```
./sample-create-resources-for-signing-4.sh
```
## 2. Configure signature verification on OpenShift
### 2.1. Configure policy.json
Note that in this scenaro, image verification is done by using a master node. So, the configuration is done only on the master node. If the image verification needs to be configured for the entire environment, the configuration needs to be populated to the each nodes.
Login to a master node. Then modify /etc/containers/policy.json file as follows:
```
sudo vi /etc/containers/policy.json
```
The original contents looks like this:
```
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports":
        {
            "docker-daemon":
                {
                    "": [{"type":"insecureAcceptAnything"}]
                }
        }
}
```
Insert several lines before "docker-daemon" as follows:
```
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports":
        {
            "docker": {
                "image-registry.openshift-image-registry.svc:5000/kabanero-signed": [
                    {
                        "keyType": "GPGKeys",
                        "type": "signedBy",
                        "keyPath": "/etc/pki/rpm-gpg/signingkey.pub"
                    }
                ]
            },
            "docker-daemon":
                {
                    "": [{"type":"insecureAcceptAnything"}]
                }
        }
}
```
Save the file.

### 2.2. Copy the public key.
run the following command to copy the signingkey.pub which was created in step 1.2.
```
sudo scp <userid>@<host where signingkey.pub exists>:/<path name>/signingkey.pub /etc/pki/rpm-gpg/
```
### 2.3. Verify that configuration.
Now, validate the configuration is done correctly. To verify the configuration, pull the image httpd from docker.io and store it to the internal image registry in kabanero-signed namespace. Then verify that the image cannot be pulled.
First login to podman with admin id.
```
podman login 
```
Store the image to the internal image registry
```
podman pull docker.io/httpd
podman push --remove-signatures httpd docker://image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd
podman rmi docker.io/library/httpd
```
Now verify that the image cannot be pulled.
```
podman pull docker://image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd
```
If it is configured correctly, the following error is shown:
```
Error: error pulling image "docker://image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd": unable to pull docker://image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd: unable to pull image: Source image rejected: A signature was required, but no signature exists
```

## 3. Run the signing pipeline
### 3.1. Run sample signing pipeline
Run following command on the machine where the sample exists. This sample is pulling the httpd image from docker.io, sign the image, then store it into local image registry as image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd:latest
```
./sample-signing-pipeline-run.sh
```
Wait for a few minutes. And run the following command to get the result.
```
oc -n kabanero describe pipelinerun.tekton.dev/image-signing-manual-pipeline-run
```
## 4. Verify that the image can be pulled.
### 4.1. Verify that the image can be pulled.
Now verify that the image can be pulled.
```
podman pull docker://image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd
```
If it is configured correctly, the following output is shown:
```
Trying to pull docker://image-registry.openshift-image-registry.svc:5000/kabanero-signed/httpd...Getting image source signatures
Checking if image destination supports signatures
Copying blob 8eb779d8bd44 done
Copying blob 30d7fa9ec230 done
Copying blob ede292f2b031 done
Copying blob 574add29ec5c done
Copying blob 8d691f585fa8 done
Copying config d3017f59d5 done
Writing manifest to image destination
Storing signatures
d3017f59d5e25daba517ac35eaf4b862dce70d2af5f27bf40bef5f936c8b2e1f
```
## 5. Congratulations for completing the sample scenario.


