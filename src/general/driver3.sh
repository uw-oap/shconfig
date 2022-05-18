#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting driver"

if [ -z "$DEBUG" ]
then
    YUM_OPTS="-q -e 0"
else
    YUM_OPTS=""
fi

# 2019-10-23: maybe this will make things faster??
yum makecache fast $YUM_OPTS --config="{{driver_rundir}}/os/yum.conf" --enablerepo=epel

if [ "{{shconfig_app_type}}" == "wp" ]
then
    # WordPress
    ./setup_wordpress.sh

    if [ "{{shconfig_env_type}}" != "dev" ]
    then
	# replace crontab:
	crontab "{{driver_rundir}}/cron/wp-crontab"
    fi

    # apache config:
    if [ "{{shconfig_env_type}}" == "dev" ]
    then
	for i in apache/fixme.conf
	do
	    conf_filename=${i##*/}
	    if [ ! -e "{{apache_conf_dir}}/$conf_filename" ]
	    then
		log_output local1.debug "{{apache_conf_dir}}/$conf_filename does not exist, need to restart web server"
		set_web_restart_needed
	    elif ! file_md5_equal "$i" "{{apache_conf_dir}}/$conf_filename"
	    then
		log_output local1.debug "$i md5 sum not equal to $conf_filename, need to restart web server"
		set_web_restart_needed
	    fi
	    sudo install -CD -m 0444 $i "{{apache_conf_dir}}/$conf_filename"
	done
    elif [ "{{shconfig_env_type}}" == "stg" ]
    then
	for i in apache/fixme.conf
	do
	    conf_filename=${i##*/}
	    if [ ! -e "{{apache_conf_dir}}/$conf_filename" ]
	    then
		set_web_restart_needed
	    elif ! file_md5_equal "$i" "{{apache_conf_dir}}/$conf_filename"
	    then
		set_web_restart_needed
	    fi
	    install -CD -m 0444 $i "{{apache_conf_dir}}/$conf_filename"
	done
	    
    elif [ "{{shconfig_env_type}}" == "prd" ]
    then
	for i in apache/fixme.conf
	do
	    conf_filename=${i##*/}
	    if [ ! -e "{{apache_conf_dir}}/$conf_filename" ]
	    then
		set_web_restart_needed
	    elif ! file_md5_equal "$i" "{{apache_conf_dir}}/$conf_filename"
	    then
		set_web_restart_needed
	    fi
	    install -CD -m 0444 $i "{{apache_conf_dir}}/$conf_filename"
	done
    fi

elif [ "{{shconfig_app_type}}" == "web" ]
then

    # RT
    ./setup_rt.sh

    # PHP apps setup
    # the source is important so that we get PHPBREW_HOME et al populated:
    . ./setup_phpbrew.sh

    if [ "{{shconfig_env_type}}" != "dev" ]
    then
	# replace crontab:
	crontab "{{driver_rundir}}/cron/web-crontab"
    fi

    # apache config:
    if [ "{{shconfig_env_type}}" == "dev" ]
    then
	for i in apache/fixme.conf 
	do
	    conf_filename=${i##*/}
	    if [ ! -e "{{apache_conf_dir}}/$conf_filename" ]
	    then
		log_output local1.debug "{{apache_conf_dir}}/$conf_filename does not exist, need to restart web server"
		set_web_restart_needed
	    elif ! file_md5_equal "$i" "{{apache_conf_dir}}/$conf_filename"
	    then
		log_output local1.debug "$i md5 sum not equal to $conf_filename, need to restart web server"
		set_web_restart_needed
	    fi
	    sudo install -CD -m 0444 $i "{{apache_conf_dir}}/$conf_filename"
	done
    elif [ "{{shconfig_env_type}}" == "stg" ]
    then
	for i in apache/fixme.conf
	do
	    conf_filename=${i##*/}
	    if [ ! -e "{{apache_conf_dir}}/$conf_filename" ]
	    then
		set_web_restart_needed
	    elif ! file_md5_equal "$i" "{{apache_conf_dir}}/$conf_filename"
	    then
		set_web_restart_needed
	    fi
	    install -CD -m 0444 $i "{{apache_conf_dir}}/$conf_filename"
	done
	    
    elif [ "{{shconfig_env_type}}" == "prd" ]
    then
	for i in apache/fixme.conf
	do
	    conf_filename=${i##*/}
	    if [ ! -e "{{apache_conf_dir}}/$conf_filename" ]
	    then
		set_web_restart_needed
	    elif ! file_md5_equal "$i" "{{apache_conf_dir}}/$conf_filename"
	    then
		set_web_restart_needed
	    fi
	    install -CD -m 0444 $i "{{apache_conf_dir}}/$conf_filename"
	done
    fi

elif [ "{{shconfig_app_type}}" == "db" ]
then
    . ./db_functions.sh

    log_output local1.debug "Running sync_appusers..."
    run_sql_from_file mysql/sync_appusers.sql
    log_output local1.debug "Running sync_users..."
    run_sql_from_file mysql/sync_users.sql

    # This is forced because the DB grants include references to
    # specific tables. If these tables don't yet exist, then the
    # grants won't work at all. `driver.sh` should be re-run after the
    # databases are loaded.
    log_output local1.debug "Running db_grants..."
    # || true needed so the grep error code of 1 for a match doesn't stop the script
    GRANT_OUTPUT=$(force_run_sql_from_file mysql/db_grants.sql 2>&1 | grep -v "doesn't exist") || true

    if ! [ -z "$GRANT_OUTPUT" ]
    then
	log_output local1.error "Error in mysql/db_grants.sql: $GRANT_OUTPUT"
	exit 1
    fi

    log_output local1.debug "Checking mysql .cnf file"
    if ! [ -e "{{mysql_cnf_file}}" ]
    then
	log_output local1.error "MySQL configuration file {{mysql_cnf_file}} not found; need to create it"
	set_db_restart_needed
    else
	# want to compare the *end* of the MySQL .cnf file to shconfig.cnf
	DEST_CMP_FILE=$(mktemp)
	# Print out every line beginning with a match for # shconfig
	perl -ne 'print if /^#.*\bshconfig\b/..0' "{{mysql_cnf_file}}" > "$DEST_CMP_FILE"
	if ! file_md5_equal mysql/shconfig.cnf "$DEST_CMP_FILE"
	then
	    log_output local1.debug "{{driver_rundir}}/mysql/shconfig.cnf different from {{mysql_cnf_file}}"
	    set_db_restart_needed
	fi
	# clean up the temp file
	rm "$DEST_CMP_FILE"
    fi

    if [ "{{shconfig_env_type}}" != "dev" ]
    then
	# replace crontab:
	crontab "{{driver_rundir}}/cron/db-crontab"
    fi

fi

if [ "{{shconfig_env_type}}" == "dev" ]
then
    log_output local1.debug "Running sudo commands"
    sudo install -C -b -o 0 -g 0 -m 444 dev/hosts /etc/hosts

    ./sudo.sh
else
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
	log_output local1.info "  rm '{{driver_vardir}}/rt-autoassign-install"
    fi
	
    if [ -e "{{driver_vardir}}/httpd-restart" ]
    then
	log_output local1.info "Please reload httpd (and php-fpm if applicable); then please run the below to remove this message:"
	log_output local1.info "  rm '{{driver_vardir}}/httpd-restart'"
    fi
    if [ -e "{{driver_vardir}}/mariadb-restart" ]
    then
	# FIXME this should tell you to update the my.cnf file
	log_output local1.info "Please reload mysqld; then please run the below to remove this message:"
	log_output local1.info "  rm '{{driver_vardir}}/mariadb-restart'"
    fi
fi

log_output local1.debug "Everything's complete."

