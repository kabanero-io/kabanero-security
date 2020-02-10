# Kabanero Application  Single-signon

## Key Concepts / Background
- As part of the security story for Kabanero, we need a way for application runtimes to be able to offer a single-signon option (based on Open ID Connect) out of the box.

[High level overview](../design/kabanero_app_sso.pdf)

## User stories
- As Champ (solution architect), I would like to be able to ensure that there is a single signon server (OIDC Provider/Server) available for application runtimes to use as part of the Kabanero install/operator in order to offer an immediate SSO experience.

## As-is

- There is no default application SSO environment in the OpenShift/Kabanero environment.

## To-be
- When a Kabanero instance is installed, regardless of the runtime stack in use, there is a running single sign-on server, based on Open ID Connect.

## Main Feature design

- The following are the steps we will automate, installing and operating a RH-SSO/Keycloak instance in the Kabanero environment:
#### 1) xxxxxxx

#### 2) xxxxxxx

#### 3) xxxxxxx

### Current doc on this support (README.md):

## Issues completed:
https://github.com/kabanero-io/kabanero-security/issues/47   Install/enable default SSO Provider for applications

## Follow on work :
https://github.com/kabanero-io/kabanero-security/issues/63  IAM Provide support for RH-SSO for Open Liberty - Part 2

This work will include updates to the Appsody and Open Liberty operators to support the various ways that the SSO server can be used by the app runtimes we support in Kabanero.

We will support an OIDC Register with an SSO/OIDC provider two ways:
#### 1) auto-register - for the Kabanero pipeline, if SSO is enabled, we will automatically register Liberty servers with the SSO provider (the default RH-SSO installed in the cluster)

#### 2) pre-register - we will also provide an option to do the OIDC registration manually (ie:for AppID or CloudIdentity or some other OIDC provider) and then provide the config related to this to Liberty (feature, client secret, client ID, discoveryURL).  

## Discussion :
