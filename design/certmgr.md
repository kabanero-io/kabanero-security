# Kabanero Certificate Manager

## Key Concepts / Background
- As part of the security story for Kabanero, we need a way for application runtimes to be able to get Certificate Authority signed personal server certificates.
This allows microservices running in different runtimes (ie: Open Liberty server instances) to communicate over TLS with minimal configuration.

[High level overview](../design/Kabanero_scan_sign.pdf)

## User stories
- As Champ (solution architect), I would like to be able to ensure that there is a certificate manager started in the cluster for my application runtimes to use to get personal CA-signed server certs.

## As-is

- There is no default certificate manager in the Kabanero environment.

## To-be
- When a Kabanero instance is installed, regardless of the runtime stack in use, there is a running certificate manager started in the cluster.

## Main Feature design

- The following are the steps we will automate in order to enable a certificate manager instance in the cluster:
https://github.com/jtmulvey/kabanero-security/tree/master/certmanager/samples/openliberty

## Follow on work :  
This is currently a prototype/sample. We are now working with the Red Hat OpenShift team on formalizing a certificate manager operator.

## Discussion :
- Enabling the cert manager in the Kabanero operator was one option for this support that we considered and decided to defer. The reason is that there is already a cert manager in the OpenShift catalog (AMQ Cert Manager) and it indicates it is a singleton in the cluster.  We have discussed this with Red Hat and are now working on a proper solution.
