# Sample image signing operator 
The kabanero-security image signing operator is a sample operator for image signing which is capable to generate or import a keypair for image signing and create a secret resource which the image signing task consumes in the Kabanero pipeline.

# About image signing operator

The image signing opeator is for automating various configurations which are required enabling the image signing by the Tekton pipeline in Kanabero.
The current code does following:
- generate or import RSA keypair for the image signing based on the values of ImageSigning custom resource instance.
- create the signature-secret-key secret resource from the RSA keypair. This secret is consued by the image signing task of Tekton pipeline.
- When the ImageSignig custom resource is deleted, the corresponding signature-secret-key resource is also deleted.
- If the generated signature-secret-key resource is deleted, the same secret will be created by the image signing operator.

# Build and install the image signing operator

## Prerequisite

The image signing operator is developed using operator-sdk version 0.11.0.

In order to build and deploy the operator, the following prerequisite packages need to be installed:
- go version 1.13 or later
- operator SDK version 1.11.0
- Openshift Container Platform 4.2 CLI

## Building the sample operator

### Clone the image signing operator

```
git clone https://github.com/kabanero-io/kabanero-security/pipelines/samples/signing-operator
cd signing-operator
```

You will need to examine the Makefile and set any necessary variables to push your container images to the correct repository. Especially, make sure that the variable of REPO is point to the corret repository, otherwise, the image will not pe pushed.

### Login to OCP 
(example)
```
oc login -u admin -p admin https://openshift.my.com:8443/
```

### Build image and push the image to the specified image repository

```
make build-image
make push-image
```

### Deploy the operator and sets required resources.

```
make deploy
```

Make sure that the image signing operator is running.

```
oc get pods -n kabanero
```
(example command output)
```
[admin@openshift signing-operator]# oc get pods -n kabanero
NAME                                                       READY   STATUS    RESTARTS   AGE
signing-operator-77b489cf7f-n4d9z                          1/1     Running   0          49s
```

### Create a image signing custom resource instance for generating a keypair.

Modify signing-operator/deploy/crds/security.kabanero.io_v1alpha1_imagesigning_generate_sample_cr.yaml to configure the identity of the keypair. 
(example)
```
apiVersion: security.kabanero.io/v1alpha1
kind: ImageSigning
metadata:
  name: default
spec:
  identity:
    name: ImageSigning
    email: security@example.com
```

If there is existing keypair which you want to use for image signing, place armored secret (private) key and public key to the image signing custom resource.  Refer to the example of signing-operator/deploy/crds/security.kabanero.io_v1alpha1_imagesigning_import_sample_cr.yaml
(example)
```
apiVersion: security.kabanero.io/v1alpha1
kind: ImageSigning
metadata:
  name: default
spec:
  keypair:
    secretKey: |-
      -----BEGIN PGP PRIVATE KEY BLOCK-----

      xcLYBF4pvTUBCACjpPW2rx20Dzd4i/6CBxc6csvk328dfp8WdR4b21lX5vRIoEN6
      lJLMU6+Z6faCpqGF8p2S2sl8AyigqbCJXE2U194INxCHuAR6VrnFASQATVyqfURA
      AtU33lWrEXFnzpEJuEyZ6VdTUsp0mECbJoA+YkgW3h48Ed11gRQs4biGtb7ZP1F0
      taRx6/eB0DdarPpbO8e/pWyp9Afi8gqkC86ZcXMSz5LEaifIdBW/qrPvOYRI6e5m
      sgwzPz7Cezqyz/hTnjZhDXFd+3bBxSG8q6T9raC7Qt0TSW6N9BVpgIcmIiLApEvE
      s5ibuptev842ypG9KreiyPSORRY+GGshuMJ1ABEBAAEAB/9T/u0cawA9Fv5rAriN
      N2SF3LypasJXClJQLadZtxpB00saKCDav34mIOJmhz+/yhXociLNaT24SMrGxLLX
      nqg3uSG/Z7w1XY/216Mc6rv2576jyA6LKKkWtymT2C00kkPCEHZJHgtzunAurqOi
      v31eCAZmrnYocScSFEIt02JqyfaMTbnPhE3A71Nj/ZaTBbJmSgsLUeXlc1tSv1fG
      ZwgbdswdTdmwMY2DjOGn0gqH5sgyPe8wwh/sNw3m/IKvxzqMWGteXmBWl5gRQ6Xn
      mTupCz3Ldeks74aeX3vSvwIS5S91hjSVLXO9Bn49UCMMDK3GVGlNAGfLSm0yfvm4
      nHOBBADYeK4YhPXcQ/G/qgAlWdQ3jk0Hw51t5yOqprW51atWzQ0LjJ5FBWHxO1G6
      hOToO47XPmEejWJtbFX3kbvnZrzH6stAoibpFQ58tkb78n28ewpzktdzif5PWAAt
      QRDiJ25U0G9fvYADKojfbwMm/mnUwVCP7/jNth52gRD9RuKaVQQAwYbKknYTf/bm
      1RsOicx0uLG6965O/Tx94PmUjVb5WnEpY/BiwzWkntVSWjg9oY6QhNYRkG18sqzU
      yl4MPoq7Ac7JNLD/pARINehtU+fhhcX1RtBuubf8AH001+SnOSivmdVYYI2FgiOX
      VgmEeMvnauJ+VzS2zb0YSkySUk0n56EEAISwSw2xxAGxqKU/06jkj8KTCsqr/vF/
      BvJWba14ug+VN2nwnWgnskL7cPJWUbx4k+MR9o7rnm4mcdS1cSXG5HuargdiS0L/
      w+QXZL1ZbxIz0LPJ+hgwKgRM2ZeIFqAa9D7FuETjmVnitG9XP6hjs99uNT2DB3Ci
      /vpbHi5KSPxXQ4bNI0ltYWdlU2lnbmluZyA8c2VjdXJpdHlAZXhhbXBsZS5jb20+
      wsBiBBMBCAAWBQJeKb01CRC2CeQNsEvIwQIbAwIZAQAArOgIACg/OMgZcDCjHH7L
      o1kVl/ti+EjwUSVXKV1nDF5hOvc4WqDMkUaudCmQaqlNA5qLA5kcR98xh4m+eP72
      52zsXchgrRbssHyW6x275GwEGdm/oVb3WpWAOU8gxrkHSm0+PUs75G0Tzsl42XpW
      nhLhxxrBCPn1IN6xuQwHECQZHAMxQgKE/QhziOsetUfVPebAKUE9mlRIxCiZUIhk
      mKDgA/YmrRys27pp/RnwLa6jOduynETWhLvCyyP7Y1TPX9vDn/LLL4l8OkA6I1xy
      QzMIAfMzovHcPVfmnXYtzYvJly0E6ZOb4u5oW8sFiW3bDz8Vwf+vvxIqFg5gnXU0
      SXXClok=
      =MVTl
      -----END PGP PRIVATE KEY BLOCK-----
    publicKey: |-
      -----BEGIN PGP PUBLIC KEY BLOCK-----

      xsBNBF4pvTUBCACjpPW2rx20Dzd4i/6CBxc6csvk328dfp8WdR4b21lX5vRIoEN6
      lJLMU6+Z6faCpqGF8p2S2sl8AyigqbCJXE2U194INxCHuAR6VrnFASQATVyqfURA
      AtU33lWrEXFnzpEJuEyZ6VdTUsp0mECbJoA+YkgW3h48Ed11gRQs4biGtb7ZP1F0
      taRx6/eB0DdarPpbO8e/pWyp9Afi8gqkC86ZcXMSz5LEaifIdBW/qrPvOYRI6e5m
      sgwzPz7Cezqyz/hTnjZhDXFd+3bBxSG8q6T9raC7Qt0TSW6N9BVpgIcmIiLApEvE
      s5ibuptev842ypG9KreiyPSORRY+GGshuMJ1ABEBAAHNI0ltYWdlU2lnbmluZyA8
      c2VjdXJpdHlAZXhhbXBsZS5jb20+wsBiBBMBCAAWBQJeKb01CRC2CeQNsEvIwQIb
      AwIZAQAArOgIACg/OMgZcDCjHH7Lo1kVl/ti+EjwUSVXKV1nDF5hOvc4WqDMkUau
      dCmQaqlNA5qLA5kcR98xh4m+eP7252zsXchgrRbssHyW6x275GwEGdm/oVb3WpWA
      OU8gxrkHSm0+PUs75G0Tzsl42XpWnhLhxxrBCPn1IN6xuQwHECQZHAMxQgKE/Qhz
      iOsetUfVPebAKUE9mlRIxCiZUIhkmKDgA/YmrRys27pp/RnwLa6jOduynETWhLvC
      yyP7Y1TPX9vDn/LLL4l8OkA6I1xyQzMIAfMzovHcPVfmnXYtzYvJly0E6ZOb4u5o
      W8sFiW3bDz8Vwf+vvxIqFg5gnXU0SXXClok=
      =D/n0
      -----END PGP PUBLIC KEY BLOCK----- 

After modifying the file, carete the resource

(example)
```
oc apply -f deploy/crds/security.kabanero.io_v1alpha1_imagesigning_generate_sample_cr.yaml
```

### Verify a secret is generated.

To verify that the secret run the following command.
```
oc get secret signature-secret-key -n kabanero
```
(example output)
[admin@openshift signing-operator]# oc get secret signature-secret-key -n kabanero
NAME                   TYPE     DATA   AGE
signature-secret-key   Opaque   1      4m6s
```

## Uninstall the image signature operator and it's resources

```
make undeploy
```
