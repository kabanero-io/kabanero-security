# NOTE: This repository has been forked to: https://github.com/icp4apps/kabanero-security.  Official builds will be based off that repoisotry.

# kabanero-security

Security for Kabanero has several aspects. 
1) Support for securing the K8s/Open Shift environment and creation of Kabanero instances.
2) Support for securing the creation of Kabanero collections. 
3) Security aspects of the Kabanero and Appsody build pipeline.

## Securing the creation of a Kabanero instances
The creation of the K8s/Open Shift environment that is activated in support of a Kabanero instances, is done by an Operator/Installer using an install script that enables the Kabanero operator and associated resources. This role requires cluster admin privileges in order to create new clusters/pods and other resources. The kabanero install script installs the Kabanero and Appsody operators and the other dependent resources.

When an application administrator needs to create or activate a new Kabanero instance, the Kabanero operator is used. The application administrator is not required to have an Open Shift ID and instead uses the Kabanero CLI to interact with the Kabanero (and K8s/Open Shift) environment.  Alternatively, the application administrator may have an Open Shift ID with enough privilege to start and stop Kabanero instances and Appsody pipelines (requires name space privileges but not cluster admin).

## Support for authentication and RBAC for Kabanero Collection maintenance
For the application administrator to be able to create a set of locally installed collections, they need to authenticate with a Github instance that is forked from kabanero-io. Once authenticated in Git, control over the artifacts associated with a Kabanero instance is managed using Git organization and team membership.  
The Kabanero command line interface https://github.com/kabanero-io/kabanero-command-line provides administrators with the ability list and activate collections in a Kabanero instance and send an on-boarding notification to developers explaining how to interact with Kabanero. Kabanero CLI users must be in a Git organization/team that is defined at install time as the one to be mapped to the 'admin' role. RBAC is then provided based on Git team membership.

## Kabanero and Appsody pipeline and build security
For application developers, Kabanero security is mostly focused on the build pipeline. Developers use their own static code scanning technology that is tied into Git (ie: Snyk or Appscan). We plan to offer a sample static code scanning task for the Kabanero pipeline in the future.

Security for Kabanero and Appsody application builds has several aspects. 
1) Upon a build request originated from Github, a Git web hook provides the means to trigger a Kabanero build. 
2) For build requests arriving in Kabanero (ie: into Knative endpoint then on to Tekton pipeline), there is a requirement for a set of Git credentials to be used to retrieve the source that is to be built and a set of credentials to be used to pull container images for the build from a docker registry.  These, as well as a secret, are provided by an administrator using the Tekton dashboard when the web hook is configured for a developer.
3) Build tasks runs under K8s service accounts that are secured using K8s and Open Shift RBAC. 
4) Once the application is built and the container image is created, the image will be scanned for vulnerabilities by default, including best practices for the container and known open source vulnerabilities (CVEs). Refer to: https://github.com/kabanero-io/kabanero-security/tree/master/pipelines/scanning for information on how to use OpenSCAP as a container image scanner.
5) Once the application is built and the container image is created, the image can optionall be signed for maintaining integrity. Refer to : https://github.com/kabanero-io/kabanero-security/tree/master/pipelines/samples/signing/
 for information on how to sign a container image and validate the image signature.

### Git web hooks and the build pipeline
A web hook that the application administrator configures for developers contains the needed information about how and where builds are to be run in a targeted Kabanero instance.  This includes a URL to a Kabanero pipeline proxy, a secret that is used to secure requests sent to Kabanero, and the needed credentials for the build task to retrieve the application source and required docker images. The Tekton dashboard UI is used to create a web hook for a developer.

When a build is requested, the web hook issues a POST on the configured URL and passes the associated context in the body of the request.  The Kabanero pipeline proxy (a Knative endpoint) accepts the request and verifies the requester's secret before forwarding the build request to a build engine (Tekton) using a Kubectl apply. The Git and container repo credentials are provided to the build engine as secrets.  The build engine consumes these, using them to pull the Git source project and the needed containers to build the application and install it in the target runtime (ie: Open Liberty) and create a container for it.

The container created in the build may be tagged, signed, and scanned for vulnerabilties.  The service account that the build engine is configured to run under is provided access to system resources under Open Shift RBAC. Once the container passes the scan, it is stored in the configured Kabanero instance's container registry. Credentials for this are built into the Kabanero pipeline configuration and stored as secrets.

### Developers access to build and application logs
Developers that need to view build or application logs are required to have an Open Shift userid. For build logs developers need to authenticate with the Tekton Dashboard and can then view all build logs. There is not yet any fine grained role based access (RBAC) for the build logs, a successful login is all that is required. For access to application runtime logs, developers require an ID with SSH privileges so they may login to the Pod and view the logs. If ELK or EFK are installed and enabled, developers could also view logs using Kibana.

### Sample image signature server
The sample image signature server can be used as an augmenting server for any existing image registry to support the image signing and verification which is defined by [signature data](https://github.com/containers/image/blob/master/docs/containers-signature.5.md) and [access protocol](https://github.com/containers/image/blob/master/docs/signature-protocols.md). Refer to [this documentation](https://github.com/kabanero-io/kabanero-security/blob/master/signature-server/sample/README.md) for more information.
