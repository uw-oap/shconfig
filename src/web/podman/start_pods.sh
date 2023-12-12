#!/bin/bash

DRIVER_UID="{{driver_uid}}"
DRIVER_GID="{{driver_gid}}"

POD_ARGUMENTS=" --replace "
CONTAINER_ARGUMENTS=" --replace "

# https://stackoverflow.com/a/21372328
if [ "$(id -u)" -ne 0 ]; then echo "Please run as root." >&2; exit 1; fi

# FIXME
if [ -z $(podman ps -q -f "name=^FIXME$") ]
then
    echo "Starting FIXME"
    podman run $CONTAINER_ARGUMENTS \
	   --name FIXME \
	   --sysctl net.ipv4.ip_unprivileged_port_start=0 \
	   --user "$DRIVER_UID:$DRIVER_GID" \
	   --userns=keep-id \
	   -d \
	   -h {{driver_hostname}} \
	   -p 127.0.0.1:{{FIXME_port}}:80 \
	   FIXME:FIXME
fi
