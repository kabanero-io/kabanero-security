# Sample Dockerfile for entitled build for a scanner image.
# See https://docs.openshift.com/container-platform/4.1/builds/running-entitled-builds.html for other ways to run entitled builds.
FROM registry.access.redhat.com/rhel7/openscap:latest
USER root
# Copy entitlements
COPY ./etc-pki-entitlement /etc/pki/entitlement
COPY ./etc-pki-consumer /etc/pki/consumer
# Copy subscription manager configuration and certificate authority files
COPY ./rhsm-conf /etc/rhsm
COPY ./rhsm-ca /etc/rhsm/ca
# Delete /etc/rhsm-host to use entitlements from the build container
RUN rm /etc/rhsm-host && \
    # Initialize /etc/yum.repos.d/redhat.repo
    # See https://access.redhat.com/solutions/1443553
    yum repolist --disablerepo=* && \
    subscription-manager repos --enable rhel-7-server-extras-rpms && \
#    yum -v -y update && \
    yum -v -y install docker-1.13.1 docker-python atomic && \
    yum clean all -y && \
    # Remove entitlements and Subscription Manager config files
    rm -rf /etc/pki/entitlement && \
    rm -rf /etc/pki/consumer && \
    rm -rf /etc/rhsm
# The oscap-docker tool requires privileged access to mount the filesystem of the image or container for offline scanning.