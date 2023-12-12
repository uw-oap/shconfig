#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting setup_podman.sh"

install -m 0500 -t "{{driver_bindir}}" \
	"{{driver_rundir}}/podman/upload_image.sh" \
	"{{driver_rundir}}/podman/update_pods.sh" \
	"{{driver_rundir}}/podman/start_pods.sh" \
	"{{driver_rundir}}/podman/restart_portal.sh" \
	"{{driver_rundir}}/podman/restart_lux.sh"

if [ "{{shconfig_env_type}}" == "dev" ]
then
    install -m 0500 -t "{{driver_bindir}}" \
	    "{{driver_rundir}}/podman/run_in_dev.sh"
fi
