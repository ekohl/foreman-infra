#!/bin/bash -e
pushd /root/koji-sync/podman/repos
dnf reposync --repoid AppStream --repoid PowerTools --repoid BaseOS --download-metadata
/usr/local/bin/rhel8-split.sh
