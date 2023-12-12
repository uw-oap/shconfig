#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting driver"

function set_web_restart_needed {
    touch "{{driver_vardir}}/httpd-restart"
}

# Podman
./setup_podman.sh

# apache config:
if [ "{{shconfig_env_type}}" == "dev" ]
then
    sudo_install_conf FIXME "{{apache_conf_dir}}/FIXME.conf"
    
else
    install_conf apache/apache-global "{{apache_conf_dir}}/apache-global"

    install_conf FIXME "{{apache_conf_dir}}/FIXME.conf"
fi



if [ "{{shconfig_env_type}}" != "dev" ]
then
	# replace crontab:
	crontab "{{driver_rundir}}/cron/web-crontab"
fi

if [ "{{shconfig_env_type}}" == "dev" ]
then
    log_output local1.debug "Running sudo commands"
    sudo install -C -b -o 0 -g 0 -m 444 dev/hosts /etc/hosts
    sudo install -C -b -o 0 -g 0 -m 444 dev/resolv.conf /etc/resolv.conf

    # Make sure apache_user is in apache_group
    sudo usermod -G {{apache_group}} {{apache_user}}

    # needed if new web sites added:
    if [ -e "{{driver_vardir}}/httpd-restart" ]
    then
	log_output local1.info "Restarting web server..."
	sudo systemctl restart apache2
	rm "{{driver_vardir}}/httpd-restart"
    fi

fi

if [ -e "{{driver_vardir}}/rt-install" ]
then
	log_output local1.info "Please install RT:"
	log_output local1.info "  cd '{{driver_builddir}}/rt-{{rt_version}}' && make fixdeps"
	log_output local1.info "  cd '{{driver_builddir}}/rt-{{rt_version}}' && sudo make install"
	log_output local1.info ""
	log_output local1.info "After the above, restart the web server."
	log_output local1.info ""
	log_output local1.info "Once this is done; please run the below to remove this message:"
	log_output local1.info "  rm '{{driver_vardir}}/rt-install'"
fi
if [ -e "{{driver_vardir}}/rt-autoassign-install" ]
then
	log_output local1.info "Please install RT autoassignment:"
	log_output local1.info "  cd '{{driver_builddir}}/RT-Extension-AutomaticAssignment' && sudo make install"
	log_output local1.info ""
	log_output local1.info "After the above, restart the web server."
	log_output local1.info ""
	log_output local1.info "Once this is done; please run the below to remove this message:"
	log_output local1.info "  rm '{{driver_vardir}}/rt-autoassign-install'"
fi


log_output local1.debug "Everything's complete."

