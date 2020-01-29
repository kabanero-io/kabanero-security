# Kabanero Image Scanner
The kabanero-security repository contains a task, pipeline, and image for scanning images built in the Kabanero pipeline.

# Prerequisites

Login to your cluster.
```
oc login <master node IP>:8443
```

Switch to working in the kabanero namespace
```
oc project kabanero
```

## Optional: Build the sample scanner image
Use the kabanero/scanner:1.3.1 image or optionally build a new one.
```
cd ./images/scanner
./build.sh
```

The build creates the image,
```
docker-registry.default.svc:5000/kabanero/scanner
```

## Optional: Mount a host path with additional SCAP content
You can optionally update the scan-task.yaml to include additional XCCDF and OVAL definition files.
Add mountPath to the scan-image step,
```
        - name: scap-content
          mountPath: /scap/content
```

If you installed the scap-security-guide using,
```
yum install scap-security-guide
```

then add the following scap-content volume. This example uses the scap-security-guide path and you can modify it to use the path the SCAP content is located.
```
    - name: scap-content
      hostPath:
        path: /usr/share/xml/scap/ssg/content/
```

## Use the scan-task from your pipeline

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

## Create the PipelineResource

Ensure that a PipelineResource containing the git and docker repositories information is created before running the pipeline.

## Activate the task

```
oc apply -f scan-task.yaml
oc apply -f <pipeline.yaml>
```

## Run the pipeline

Sample PipelineRun files are provided under ./pipelines/manual-pipeline-runs.  Locate the appropriate pipeline-run file and execute it.
```
oc apply -f <collection-name>-pipeline-run.yaml
```

## Check the status of the pipeline run

```
oc get pipelineruns
oc -n kabanero describe pipelinerun.tekton.dev/<pipeline-run-name> 
```

## Execute pipelines using the Tekton Dashboard

You can also login to the Tekton Dashboard and create a new pipeline run to execute the pipeline that uses the scan-task Task.

## Scan results

The scan results are stored by default in the /var/lib/kabanero/scans directory of the worker node that runs the pod for the PipelineRun executing the scan. The files are named scan-oval-results.xml and oscap-chroot-report.html by default and these names can be modified in the scan-task.yaml file.

