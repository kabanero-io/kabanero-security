## Kabanero Scanner Image containing OpenSCAP tools
## Note: Pulling container will require logging into Red Hat's registry using `docker login registry.redhat.io` .

## Note: We're using the UBI 8 registry instead of RHEL here
FROM registry.access.redhat.com/ubi8:latest
MAINTAINER ttorres@us.ibm.com

### Required Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="Kabanero Scanner Image" \
      vendor="IBM" \
      version="1.3.4" \
      release="1.3.4" \
      summary="Kabanero Scanner Image containing OpenSCAP tools" \
      description="OpenSCAP tools necessary to run an image scan from a Tekton pipeline, built from the OpenSCAP version and pull request indicated in the release label."

### add licenses to this directory
COPY licenses /licenses

### Copy repository configuration for temporary tools needed during the build that will be removed after OpenSCAP is built.
COPY /etc/yum.repos.d /etc/yum.repos.d

### Add necessary Red Hat repos here
## Note: The UBI has different repos than the RHEL repos.
RUN REPOLIST=ubi-8-baseos,ubi-8-codeready-builder,ubi-8-appstream \
    VERSION=1.3.4 \
### Add your package needs here
    INSTALL_PKGS="libcurl-devel libgcrypt-devel libselinux-devel libxml2-devel libxslt-devel openldap-devel pcre-devel perl-devel python36-devel bzip2-devel libyaml-devel" \
    TEMP_BUILD_UBI_PKGS="wget make gcc-c++" \
    INSTALL_OTHER_PKGS="dbus-devel libacl-devel libblkid-devel libcap-devel libattr-devel perl-XML-Parser perl-XML-XPath rpm-devel" \
    TEMP_BUILD_OTHER_PKGS="cmake git swig" \
    REMOVE_PKGS="kernel-headers vim-minimal" && \
    yum -y update --setopt=tsflags=nodocs --allowerasing && \ 
    yum -y update-minimal --disablerepo "*" --enablerepo ubi-8* --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum repolist && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${TEMP_BUILD_UBI_PKGS} && \
    yum -y install --disablerepo "ubi-*" --setopt=tsflags=nodocs ${INSTALL_OTHER_PKGS} && \
    yum -y install --disablerepo "ubi-*" --setopt=tsflags=nodocs ${TEMP_BUILD_OTHER_PKGS} && \

### Install your application here -- add all other necessary items to build your image
    wget https://github.com/OpenSCAP/openscap/releases/download/${VERSION}/openscap-${VERSION}.tar.gz && \
    wget https://github.com/OpenSCAP/openscap/releases/download/${VERSION}/openscap-${VERSION}.tar.gz.sha512 && \
    sha512sum -c openscap-${VERSION}.tar.gz.sha512 && \
    tar -xzpf openscap-${VERSION}.tar.gz && \
    cd openscap-${VERSION} && \
    mkdir -p build && \
#
#    git clone https://github.com/OpenSCAP/openscap.git && \
#    cd openscap && \
#    git checkout maint-1.3 && \
    cd build && \
    cmake -DENABLE_OSCAP_UTIL=TRUE -DENABLE_OSCAP_UTIL_CHROOT=TRUE -DENABLE_OSCAP_UTIL_PODMAN=TRUE ../ && \
    make && \
    make install && \
    yum -y remove --setopt=tsflags=nodocs ${TEMP_BUILD_UBI_PKGS} ${TEMP_BUILD_OTHER_PKGS} ${REMOVE_PKGS} && \
    yum clean all -y && \
    # Remove repos' configs
    rm -rf /etc/rhsm /etc/yum.repos.d /etc/pki/entitlement /etc/pki/rpm-gpg

