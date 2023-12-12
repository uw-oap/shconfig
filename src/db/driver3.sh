#!/bin/bash
#
# 2023-04-26 - moving driver3 into separate files
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
. ./db_functions.sh
assert_driver

log_output local1.debug "Starting driver"

log_output local1.debug "Running sync_users..."
run_sql_from_file mysql/sync_users.sql

# This is forced because the DB grants include references to
# specific tables. If these tables don't yet exist, then the
# grants won't work at all. `driver.sh` should be re-run after the
# databases are loaded.
#
log_output local1.debug "Running db_grants..."
# || true needed so the grep error code of 1 for a match doesn't stop the script
GRANT_OUTPUT=$(force_run_sql_from_file mysql/db_grants.sql 2>&1 | grep -v "doesn't exist") || true

if ! [ -z "$GRANT_OUTPUT" ]
then
	log_output local1.error "Error in mysql/db_grants.sql: $GRANT_OUTPUT"
	exit 1
fi

log_output local1.debug "Running variable update..."
run_sql_from_file mysql/set_variables.sql


if [ "{{shconfig_env_type}}" != "dev" ]
then
	# replace crontab:
	crontab "{{driver_rundir}}/cron/db-crontab"
fi

if [ "{{shconfig_env_type}}" == "dev" ]
then
    log_output local1.debug "Running sudo commands"
    sudo install -C -b -o 0 -g 0 -m 444 dev/hosts /etc/hosts
    sudo install -C -b -o 0 -g 0 -m 444 dev/resolv.conf /etc/resolv.conf

    . ./db_functions.sh
    run_sql_from_file mysql/dev_db_grants.sql

    # if file doesn't exist, or it's different
    if ! diff -q "{{driver_rundir}}/mysql/db3.cnf" "/etc/mysql/conf.d/db3.cnf" >/dev/null 2>&1
    then
	logger local1.info "Installing MySQL conf file and restarting"
	sudo install -C -m 0444 "{{driver_rundir}}/dev/db3.cnf" "/etc/mysql/conf.d/db3.cnf"
	sudo systemctl restart mysql
    fi
fi

log_output local1.debug "Everything's complete."
