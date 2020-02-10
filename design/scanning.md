# Kabanero Security Container Scanning 

## Key Concepts / Background
- As part of the devsecops story for Kabanero, we need to offer an out of the box container scanning task in the build pipeline.

[High level overview](../design/Kabanero_scan_sign.pdf)

## User stories
- As Champ (architect), I would like to be able to ensure that there is a container scanning task in the build pipeline in order to ensure we are able to verify the contents of any containers before they are made ready for deployment.

## As-is

- There is no default container scanning in the Kabanero Tekton pipeline

## To-be
- When a Kabanero instance is installed, regardless of the runtime stack in use, there is an OpenScap-based container scan task enabled in the Tekton pipeline

## Main Feature design

- The following are the steps we will automate in order to enable container scanning in the Kabanero pipeline:
### Done during build:
#### 1) Download and build an OpenScap scanner image:
See: https://www.open-scap.org/download/

#### 2) Add OVAL and XCCDF definition files to the image and upload it to DockerHub (in kabanero/scanner)
Champ needs to be able to customize the scanning options. This needs to be done with configuration (indicating what sets of OVAL or XCCDF rules should be used for the scan).

### Done as part of Kabanero pipelines impl:
#### 3) Update scan-pipeline.yaml to include the pipeline task for scanning.  Sample:

The scan-pipeline.yaml file can be used to run the scan-task task. Add the resources and tasks to your pipeline,

```
  resources:
    - name: git-source
      type: git
    - name: docker-image
      type: image
  tasks:
    - name: kabanero-scan
      taskRef:
        name: scan-task
      resources:
        inputs:
        - name: git-source
          resource: git-source
        - name: docker-image
          resource: docker-image
      params:
      - name: command
        value: oscap-chroot
      - name: pathToRootfs
        value: /workspace/image_rootfs
      - name: scansDir
        value: kabanero/scans
      - name: pathToInputFile
        value: /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml
```
If you mounted a host path with additional SCAP content, the definition file can be specified in the pathToInputFile input parameter.

### 4) Scan results
The results.xml and report.html files are stored by default in the /var/lib/kabanero/scans directory of the worker node that runs the pod for the PipelineRun executing the scan.

We make the scan results available from the Tekton Dashboard by emitting them into the task's console with delimiters showing where the report begins/ends and html report begins/ends. NOTE: This is a temporary solution and needs to be replaced by a more usable option where the scan html file can easily be served up from a developer's browser. See follow on work below.

## Container scanning issues completed:
https://github.com/kabanero-io/kabanero-security/issues/45  Container Scanning - Phase 2

https://github.com/kabanero-io/kabanero-security/issues/36  Make scan results accessible to Jane

https://github.com/kabanero-io/kabanero-security/issues/40  Provide an option to set scanning modes

## Follow on work :  
There needs to be a phase 3 of this support that addresses the following:

https://github.com/kabanero-io/kabanero-security/issues/57  Container scanning follow-ups - Phase 3

https://github.com/kabanero-io/kabanero-security/issues/39  Provide an option to halt build based on scan results

1) we need to make the html report (and possibly the full XML report) available from some kind of web file server. Requiring developers to download the Tekton Dashboard task log and have to edit it to get the html report is not an acceptable/usable solution.   
2) we need to be able to fail the build when any Red/Yellow results are found in the scan
