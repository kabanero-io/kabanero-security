# Kabanero Image Scanner
The kabanero-security repository contains a task, pipeline, and image for scanning images built in the Kabanero pipeline. Image scanning is already enabled by default in the kabanero pipelines that at least build and push an image. You can add image scanning to your own pipelines by following these instructions.

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
# Use module to specify the type of SCAP content to use. For example, oval or xccdf.
      - name: module
        value: oval
# Use options-and-arguments to specify the module's operation options and arguments.
#      - name: options-and-arguments
# To evaluate a specific definition with an OVAL file:
#        value: --id <definition-id>
# For example, --id oval:ssg-accounts_password_minlen_login_defs:def:1
#
# To evaluate a specific profile from a XCCDF benchmark file:
#        value: --profile <profile-id>
# For example, --profile hipaa
#
# To evaluate a specific profile from a XCCDF benchmark file that requires a remote resource:
#        value: --fetch-remote-resources --profile <profile-id>
# For example, --fetch-remote-resources --profile xccdf_org.ssgproject.content_profile_pci-dss
#
# To use a CPE dictionary while evaluating a specific profile:
#        value: --profile <profile-id> --cpe <dictionary-file-name relative to the task's mount point>
# For example (with SCAP content mounted to /scap/content), --profile xccdf_org.ssgproject.content_profile_ospp42 --cpe /scap/content/ssg-rhel7-cpe-dictionary.xml
#
# To evaluate a specific rule:
#        value: --profile <profile-id> --rule <rule-id>
# For example, --profile xccdf_org.ssgproject.content_profile_ospp42 --rule xccdf_org.ssgproject.content_rule_disable_host_auth
#
      - name: pathToInputFile
        value: /scap/content/ssg-rhel7-ds.xml
```

If you mounted a host path with additional SCAP content, the definition file can be specified in the pathToInputFile input parameter. Use the options-and-arguments parameter to customize the scan by specifying the module's operation options and arguments. Visit http://static.open-scap.org/openscap-1.3/oscap_user_manual.html#_scanning_with_oscap for more information on how to use the scanner options and arguments to evaluate specific profiles, rules, and definitions.

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

The results.xml and report.html files are stored by default in the /var/lib/kabanero/scans directory of the worker node that runs the pod for the PipelineRun executing the scan.

