# kabanero-security

Security for Kabanero is has several aspects. 
1) Support for securing the creation of Kabanero instances.
2) Support for securing the creation of Kabanero collections. 
3) Security aspects of the Kabanero and Appsody build pipeline.

## Securing the creation of a Kabanero instances
The creation of the K8s/Open Shift environment that is activated in support of a Kabanero instances, is done by an Operator/Installer using an install script that enables the Kabanero operator and associated resources. This role requires cluster admin privileges in order to create new clusters/pods and other resources.

When an application administrator (the Champ persona) needs to create a new Kabanero instance running in the backplane, they also use the Kabanero operator and require an Open Shift ID in the IAM registry with enough priviledge to start and stop various resources (ie: doing an activate/deactivate).

## Support for authentication and RBAC for Kabanero Collection maintenance
For the application administrator (Champ persona) to be able to create a set of locally installed collections, he needs to authenticate with a Github instance that is copied off the Kabanero-io Git. Once authenticated, control over the artifacts associated with a Kabanero instance is managed using Git team membership.  Anyone acting in the administation role, must be part of the Kabanero-admins team (or similar admin-controlled team name). Read/write access to collections is then managed using Git-based RBAC.  

## Kabanero and Appsody pipeline and build security
For application developers (the Jane persona), Kabanero security is mostly focused on the build pipeline. While we expect developers to use their own static code scanning technology that is tied into Git, we offer several options as best practices in this area. <add some content here about use of Appscan or Snyk in the Git PR code commit process>
  
Security for Kabanero and Appsody application builds has several aspects. 
1) Upon a build request originated from Github, a Git web hook provides the means to trigger a Kabanero build. 
2) Once the build request arrives in the build engine (ie: Tekton pipeline), there is a requirement for a set of Git credentials to be used to retrieve the source that is to be built and a set of credentials to be used to pull container images for the build from a docker registry
3) The build itself runs under K8s service IDs that are secured using K8s and Open Shift RBAC. 
4) Once the application is built and the container is created, the container image is scanned for vulnerabilities (including best practices for the container and known open source vulnerabilities (CVEs).

### Git web hooks and the build pipeline
A web hook that the application administrator configures for developers contains the needed information about how and where builds are to be run in a targeted Kabanero instance.  This includes a URL to a Kabanero pipeline proxy, a secret that is used to secure requests sent to Kabanero, and the needed credentials for the build task to retrieve the application source and required docker images.

When a build is requested, the web hook issues a POST on the configured URL and passes the associated context in the body of the request.  The Kabanero pipeline proxy accepts the request and verifies the requester's secret before forwarding the build request to a build engine (Tekton or other) using a Kubectl apply. The secret arriving from the requester is mapped to another secret, that is used in the build engine to verify the build request (this will be a shared secret that all build engines will be configured to use).   The Git and container repo credentials are forwarded to the build engine.  The build engine consumes these, using them to pull the Git source project and the needed containers to build the application.

The container created in the build needs to be tagged and signed and scanned for vulnerabilties.  Each build step is recorded in the build logs and written to an audit log.  The service ID that the build engine is configured to run under is provided access to these logs with Open Shift RBAC verifying the access. Once the container passes the scan, it is stored in the configured Kabanero instance's container repo. Credentials for this are built into the Kabanero pipeline configuration.
