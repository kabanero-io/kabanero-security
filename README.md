# kabanero-security

Security for Kabanero is has several aspects. 
1) Support for securing the creation of Kabanero instances and the Kabanero backplane. 
2) Support for authentication and RBAC for the maintenance of Kabanero Collections (CRUD for Collections)

# Securing the creation of a Kabanero backplane and instance
The creation of the Open Shift environment that is activated in support of a Kabanero backplane, and then subsequent instances, is done by an Operator/Installer (the Todd persona) using the Kabanero operator. This role requires cluster admin privileges in order to create new clusters/pods and other resources.

When an application adminstrator (the Champ persona) needs to create a new Kabanero instance running in the backplane, they also use the Kabanero operator and require an Open Shift ID in the IAM registry with enough priviledge to start and stop various resources (ie: doing an activate/deactivate).

# Support for authentication and RBAC for Kabanero Collection maintenance
For the application administrator (Champ persona) to be able to create a set of locally installed collections, he needs to authenticate with a Github instance that is copied off the Kabanero-io Git. Once authenticated, control over the artifacts associated with a Kabanero instance is managed using Git team membership.  Anyone acting in the administation role, must be part of the Kabanero-admins team (or similar admin-controlled team name). Read/write access to collections is then managed using Git-based RBAC.  
