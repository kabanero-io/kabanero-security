#Create a self-signing ClusterIssuer
oc create -f libertySelfSignedClusterIssuer.yaml
#Create a self-signed Certificate
oc create -f libertySelfSignedCert.yaml
#Create an OpenLibertyApplication deployment
oc create -f libertyApp.yaml
#Create network route for the deployment
oc create -f libertyAppSecureRoute.yaml
