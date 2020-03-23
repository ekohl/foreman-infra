#!/bin/sh

podman build -t koji-sync .

mkdir -p podman/repos
podman run --rm -v ./podman:/root/koji-sync/podman -t koji-sync

#rsync -rv --delete -e ssh ./podman/koji/staged/ root@koji.katello.org:/mnt/koji/releases/split/yum/koji-modules/koji/staged/
