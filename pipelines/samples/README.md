# Sample image scanner
The kabanero-security repository contains sample tasks, pipelines, and images for scanning images built in the Kabanero pipeline.

# Building the sample scanner image

Login to your cluster.  For example for OKD,

```
oc login <master node IP>:8443
```

## Switch to working in the kabanero namespace
```
oc project kabanero
```

## Build the Kabanero scanner image
```
cd ./images/scanner
./build.sh
```

The build creates the image,

```
docker-registry.default.svc:5000/kabanero/scanner
```

## Use the scan-task from your pipeline

The sample scan-pipeline.yaml file can be used to run the scan-task task. Add the resources and tasks to your pipeline,

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

