# Kabanero Security Container Signing

## Key Concepts / Background
- As part of the devsecops story for Kabanero, we need to offer an out of the box container signing task in the build pipeline.

## User stories
- As Champ (architect), I would like to be able to ensure that application containers are signed when they are deployed/saved in a container registy.

## As-is

- There is no default container signing in the Kabanero Tekton pipeline

## To-be
- When a Kabanero instance is installed, regardless of the runtime stack in use, there is a Skopeo-based container signing task enabled in the Tekton pipeline

## Main Feature design

- The following are the steps we will automate in order to enable container signing in the Kabanero pipeline:
Build:
### 1) Download and build an Skopeo signing image:
See: https://github.com/containers/skopeo
### 2)Upload the image to DockerHub (in kabanero/signing) - these steps are required as part of Kabanero build

Done as part of Kabanero pipelines impl:
### 3) Update scan-pipeline.yaml to include the pipeline task for signing.  Sample:

The scan-pipeline.yaml file can be used to run the scan-task task. Add the resources and tasks to your pipeline,

```
  resources:
    - name: git-source
      type: git
    - name: docker-image
      type: image
  tasks:
    - name: kabanero-sign
      taskRef:
        name: sign-task
      resources:
        inputs:
        - name: git-source
          resource: git-source
        - name: docker-image
          resource: docker-image
      params:
      - name: pathToRootfs
        value: /workspace/image_rootfs
      - name: signDir
        value: kabanero/signing
        
## For phase 2 of this support, we automate the creation of the public/private keys for signing by doing it with GPG in the Kabanero operator.

## Discussion:  
