# Dockerfile for the image containing Atomic and OpenSCAP tools for scanning.
FROM registry.access.redhat.com/ubi7:latest
USER root
# Copy repository configuration
COPY ./yum.repos.d /etc/yum.repos.d
# Delete /etc/rhsm-host to use entitlements from the build container
RUN rm /etc/rhsm-host && \
    yum-config-manager --disable ubi-* && \
    yum -v -y install atomic openscap-scanner openscap-utils scap-security-guide && \
    yum clean all -y && \
    # Remove repos' configs
    rm -rf /etc/rhsm /etc/yum.repos.d /etc/pki/entitlement /etc/pki/rpm-gpg
# The atomic tool requires privileged access to mount the filesystem of the image for offline scanning.
