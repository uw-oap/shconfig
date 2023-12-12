#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting driver"

./setup_wordpress.sh

# apache and PHP config:
if [ "{{shconfig_env_type}}" == "dev" ]
then
    sudo_install_conf FIXME.conf "{{apache_conf_dir}}/FIXME.conf"

else
    install_conf apache/apache-global "{{apache_conf_dir}}/apache-global"
    install_conf FIXME.conf "{{apache_conf_dir}}/FIXME.conf"
fi

if [ "{{shconfig_env_type}}" == "dev" ]
then
    log_output local1.debug "Running sudo commands"
    sudo install -C -b -o 0 -g 0 -m 444 dev/hosts /etc/hosts
    sudo install -C -b -o 0 -g 0 -m 444 dev/resolv.conf /etc/resolv.conf

    # Make sure apache_user is in apache_group
    sudo usermod -G {{apache_group}} {{apache_user}}

    if [ -e "{{driver_vardir}}/httpd-restart" ]
    then
	log_output local1.info "Restarting web server..."
	sudo systemctl restart apache2
	sudo systemctl restart php8.1-fpm
	rm "{{driver_vardir}}/httpd-restart"
    fi
fi

log_output local1.debug "Everything's complete."

