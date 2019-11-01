## Kabanero Scanner Image containing OpenSCAP tools
## Note: Pulling container will require logging into Red Hat's registry using `docker login registry.redhat.io` .

## Note: We're using the UBI 7 registry instead of RHEL here
FROM registry.access.redhat.com/ubi7:latest
MAINTAINER ttorres@us.ibm.com

### Required Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="Kabanero Scanner Image" \
      maintainer="ttorres@us.ibm.com" \
      vendor="IBM" \
      version="0.1" \
      release="0.1-0" \
      summary="Kabanero Scanner Image containing OpenSCAP tools" \
      description="OpenSCAP tools necessary to run an image scan from a Tekton pipeline"

### add licenses to this directory
COPY licenses /licenses

### Copy repository configuration for temporary tools needed during the build that will be removed after OpenSCAP is built.
COPY ./yum.repos.d /etc/yum.repos.d

### Add necessary Red Hat repos here
## Note: The UBI has different repos than the RHEL repos.
RUN REPOLIST=ubi-7,ubi-7-optional \

### Add your package needs here
    INSTALL_PKGS="" \
    TEMP_BUILD_OTHER_PKGS="cmake dbus-devel git GConf2-devel libacl-devel libblkid-devel libcap-devel libattr-devel perl-XML-Parser perl-XML-XPath python3-devel rpm-devel swig bzip2-devel" \
    TEMP_BUILD_UBI_PKGS="wget libcurl-devel libgcrypt-devel libselinux-devel libxml2-devel libxslt-devel make openldap-devel pcre-devel perl-devel gcc-c++" && \
    yum -y update-minimal --disablerepo "*" --enablerepo ubi-7 --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum repolist && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} ${TEMP_BUILD_UBI_PKGS} && \
    yum -y install --disablerepo "ubi-*" --setopt=tsflags=nodocs ${TEMP_BUILD_OTHER_PKGS} && \

### Install your application here -- add all other necessary items to build your image
    wget https://github.com/OpenSCAP/openscap/releases/download/1.3.1/openscap-1.3.1.tar.gz && \
    wget https://github.com/OpenSCAP/openscap/releases/download/1.3.1/openscap-1.3.1.tar.gz.sha512 && \
    sha512sum -c openscap-1.3.1.tar.gz.sha512 && \
    tar -xzpf openscap-1.3.1.tar.gz && \
    cd openscap-1.3.1 && \
    mkdir -p build && \
#    git clone https://github.com/OpenSCAP/openscap.git && \
#    cd openscap && \
    cd build && \
    cmake -DENABLE_OSCAP_UTIL=TRUE -DENABLE_OSCAP_UTIL_CHROOT=TRUE -DENABLE_OSCAP_UTIL_PODMAN=TRUE ../ && \
    make && \
    make install && \
    yum -y remove --setopt=tsflags=nodocs ${TEMP_BUILD_UBI_PKGS} ${TEMP_BUILD_OTHER_PKGS} && \
    yum clean all -y && \
    # Remove repos' configs
    rm -rf /etc/rhsm /etc/yum.repos.d /etc/pki/entitlement /etc/pki/rpm-gpg
