#!/bin/bash
set -e
. ../shared_functions.sh

assert_driver

if [ "{{shconfig_app_type}}" == "wp" ]
then
    if sestatus | grep 'SELinux status' | grep enabled >/dev/null
    then
	log_output local1.warning "Turning off SElinux"
	sudo setenforce 0
	sudo tee /etc/selinux/config <<EOF
SELINUX=disabled
SELINUXTYPE=targeted
EOF
    fi

    sudo usermod -G {{apache_group}} {{apache_user}}

    if [ -e "{{driver_vardir}}/httpd-restart" ]
    then
	log_output local1.info "Restarting web server..."
	sudo systemctl restart httpd
	rm "{{driver_vardir}}/httpd-restart"
    fi

elif [ "{{shconfig_app_type}}" == "web" ]
then
    if sestatus | grep 'SELinux status' | grep enabled >/dev/null
    then
	log_output local1.warning "Turning off SElinux"
	sudo setenforce 0
	sudo tee /etc/selinux/config <<EOF
SELINUX=disabled
SELINUXTYPE=targeted
EOF
    fi

    if [ -e "{{driver_vardir}}/rt-install" ]
    then
	log_output local1.info "Installing RT"
	pushd "{{driver_builddir}}/rt-{{rt_version}}" > /dev/null
	sudo make install
	sudo chown {{driver_user}}:{{apache_group}} "{{rt_dir}}/etc/RT_Config.pm"
	chmod 440 "{{rt_dir}}/etc/RT_Config.pm"
	popd > /dev/null

	# Restart the web server next:
	touch "{{driver_vardir}}/httpd-restart"
	rm "{{driver_vardir}}/rt-install"
    fi

    if [ -e "{{driver_vardir}}/rt-autoassign-install" ]
    then
	log_output local1.info "Installing RT AutoAssign"
	pushd "{{driver_builddir}}/RT-Extension-AutomaticAssignment" > /dev/null
	sudo make install
	popd > /dev/null

	touch "{{driver_vardir}}/httpd-restart"
	rm "{{driver_vardir}}/rt-autoassign-install"
    fi

    # Make sure apache_user is in apache_group
    sudo usermod -G {{apache_group}} {{apache_user}}
    sudo chown -R {{apache_user}}:{{apache_group}} "{{rt_dir}}/var/log" "{{rt_dir}}/var/mason_data"  "{{rt_dir}}/var/session_data" 

    # needed if new web sites added:
    if [ -e "{{driver_vardir}}/httpd-restart" ]
    then
	log_output local1.info "Restarting web server..."
	sudo systemctl restart httpd
	rm "{{driver_vardir}}/httpd-restart"
    fi
elif [ "{{shconfig_app_type}}" == "db" ]
then
    . ./db_functions.sh
    run_sql_from_file mysql/dev_db_grants.sql

    sudo install -CD -m 0400 mysql/cert.pem "{{mysql_sslcert_path}}"
    sudo install -CD -m 0400 mysql/cert.key "{{mysql_sslkey_path}}"

    sudo install -CD -m 0444 mysql/shconfig.cnf "{{mysql_cnf_file}}"
    if [ -e "{{driver_vardir}}/mariadb-restart" ]
    then
	log_output local1.info "Restarting database server..."
	sudo systemctl restart mysqld
	rm "{{driver_vardir}}/mariadb-restart"
    fi
fi
