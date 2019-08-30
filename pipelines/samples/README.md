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

## Create the Secrets and ConfigMaps

Replace {ID} with the actual entitlement key id.

```
cd ./images
oc create secret generic etc-pki-entitlement --from-file /etc/pki/entitlement/{ID}.pem --from-file /etc/pki/entitlement/{ID}-key.pem
oc create secret generic etc-pki-consumer --from-file /etc/pki/consumer/cert.pem --from-file /etc/pki/consumer/key.pem
oc create configmap rhsm-conf --from-file /etc/rhsm/rhsm.conf
oc create configmap rhsm-ca --from-file /etc/rhsm/ca/redhat-uep.pem --from-file /etc/rhsm/ca/katello-server-ca.pem
```

## Create the scanner BuildConfig and ImageStream

Apply the BuildConfig and ImageStream from the images directory. Edit the BuildConfig and ImageStream if you want to specify a different repository, image name, and tag.

```
oc apply -f scanner-bc.yaml -f scanner-stream.yaml
oc start-build scanner --from-file=scanner/Dockerfile --follow
```

The build creates the image,

```
docker-registry.default.svc:5000/kabanero/oscap-scanner
```

## Update the sample scan-task.yaml with the image containing the scanner

```
steps:
    - name: scan-image
      securityContext:
        privileged: true
      image: docker-registry.default.svc:5000/kabanero/scanner:latest
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
    - name: appsody-scan
      taskRef:
        name: scan-task
      resources:
        inputs:
        - name: git-source
          resource: git-source
        - name: docker-image
          resource: docker-image
      params:
      - name: command-with-flags
        value: oscap-docker image-cve
      - name: scanner-arguments
        value: --report report.html
```

## Activate the task

```
kubectl apply -f scan-task.yaml
kubectl apply -f <pipeline.yaml>
```

## Run the pipeline

Sample PipelineRun files are provided under ./pipelines/manual-pipeline-runs.  Locate the appropriate pipeline-run file and execute it.
```
kubectl apply -f <collection-name>-pipeline-run.yaml
```

## Check the status of the pipeline run

```
kubectl get pipelineruns
kubectl -n kabanero describe pipelinerun.tekton.dev/<pipeline-run-name> 
```

# Execute pipelines using Tekton Dashboard Webhook Extension

You can also leverage the Tekton Dashboard Webhook Extensions to drive the pipelines automatically by configuring webhooks to github.  Events such as commits in a github repo can be setup to automatically trigger pipeline runs.

Visit https://github.com/tektoncd/experimental/blob/master/webhooks-extension/docs/GettingStarted.md for instructions on configuring a webhook.
