#!/bin/bash
# This file is called `driver2.sh` and is called by `driver.sh` so
# that it can be updated via a `git pull` from `driver.sh`.
#
# Makes sure directories exist. Populates special vars/ files
# including by running lastpass.

set -e
. ./shared_functions.sh
assert_driver

log_output local1.debug "Running driver2"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

############################
# Set up environment a bit #
############################
mkdir -p run/os
mkdir -p build
mkdir -p var/log
mkdir -p var/backup
chmod 700 var/backup

####################################
# read/check environment variables #
####################################

if [ -e "env.sh" ]
then
    . ./env.sh
fi

if [ -z "$SHCONFIG_EMAIL" ]
then
    log_output local1.error "SHCONFIG_EMAIL not set; set to email address for non-cron jobs"
    exit 1
fi

if [ -z "$SHCONFIG_CRONEMAIL" ]
then
    log_output local1.error "SHCONFIG_CRONEMAIL not set; set to email address for cron jobs"
    exit 1
fi

if [ -z "$SHCONFIG_DBSERVER" -o -z "$SHCONFIG_WEBSERVER" -o -z "$SHCONFIG_WPSERVER" ]
then
    log_output local1.error "SHCONFIG_DBSERVER, SHCONFIG_WEBSERVER, and SHCONFIG_WPSERVER must be set"
    exit 1
fi

if [ -z "$SHCONFIG_APP_TYPE" -o -z "$SHCONFIG_ENV_TYPE" ]
then
    HOSTPART=${HOSTNAME%%.*}
    if [ "$HOSTPART" == "apprdweb3" ]
    then
	SHCONFIG_APP_TYPE="web"
	SHCONFIG_ENV_TYPE="prd"
    elif [ "$HOSTPART" == "apprddb3" ]
    then
	SHCONFIG_APP_TYPE="db"
	SHCONFIG_ENV_TYPE="prd"
    elif [ "$HOSTPART" == "apprdwp3" ]
    then
	SHCONFIG_APP_TYPE="wp"
	SHCONFIG_ENV_TYPE="prd"
    elif [ "$HOSTPART" == "apstgweb3" ]
    then
	SHCONFIG_APP_TYPE="web"
	SHCONFIG_ENV_TYPE="stg"
    elif [ "$HOSTPART" == "apstgdb3" ]
    then
	SHCONFIG_APP_TYPE="db"
	SHCONFIG_ENV_TYPE="stg"
    elif [ "$HOSTPART" == "apstgwp3" ]
    then
	SHCONFIG_APP_TYPE="wp"
	SHCONFIG_ENV_TYPE="stg"
    else
	log_output local1.error "Could not identify app type and env type; exiting"
	exit 1
    fi
fi

if [ "$SHCONFIG_APP_TYPE" != "web" -a "$SHCONFIG_APP_TYPE" != "db" -a "$SHCONFIG_APP_TYPE" != "wp" ]
then
    log_output local1.error "SHCONFIG_APP_TYPE not set to 'web' or 'db'; exiting"
    exit 1
fi

if [ "$SHCONFIG_ENV_TYPE" != "prd" -a "$SHCONFIG_ENV_TYPE" != "stg" -a "$SHCONFIG_ENV_TYPE" != "dev" ]
then
    log_output local1.error "SHCONFIG_ENV_TYPE not set to 'prd', 'stg', or 'dev'; exiting"
    exit 1
fi

if [ -z "$DRIVER_USER" ]
then
    DRIVER_USER=$USER
fi

###################################
# Make sure vars directory exists #
###################################
if ! [ -e "vars" ]
then
    ln -s "$SHCONFIG_ENV_TYPE-vars" vars
fi

#####################################
# populate vars/ with special files #
#####################################

cat > vars/shconfig.json <<EOF
{
  "app_type": "$SHCONFIG_APP_TYPE",
  "env_type": "$SHCONFIG_ENV_TYPE",
  "email": "$SHCONFIG_EMAIL",
  "cronemail": "$SHCONFIG_CRONEMAIL",
  "dbserver": "$SHCONFIG_DBSERVER",
  "webserver": "$SHCONFIG_WEBSERVER",
  "wpserver": "$SHCONFIG_WPSERVER"
}
EOF

cat > vars/dev.json <<EOF
{
   "dbserver_ip": "${SHCONFIG_DBSERVER_IP:-192.168.100.101}",
   "webserver_ip": "${SHCONFIG_WEBSERVER_IP:-192.168.100.102}",
   "wpserver_ip": "${SHCONFIG_WPSERVER_IP:-192.168.100.103}"

}
EOF

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

DRIVER_IPS=$(join_by , $(ip -br a | perl -lne 'm|(\d+\.\d+\.\d+\.\d+)| and print qq{"$1"}'))

DRIVER_UID=$(id -u "$DRIVER_USER")
DRIVER_GID=$(id -g "$DRIVER_USER")

cat > vars/driver.json <<EOF
{
  "dir": "$DRIVER_DIR",
  "bindir": "$DRIVER_DIR/bin",
  "rundir": "$DRIVER_DIR/run",
  "tmpdir": "$DRIVER_DIR/tmp",
  "vardir": "$DRIVER_DIR/var",
  "logdir": "$DRIVER_DIR/var/log",
  "backupdir": "$DRIVER_DIR/var/backup",
  "lockfile": "$DRIVER_DIR/var/lock",
  "builddir": "$DRIVER_DIR/build",
  "user": "$DRIVER_USER",
  "group": "${GROUPS[0]}",
  "uid": "$DRIVER_UID",
  "gid": "$DRIVER_GID",
  "ip_addresses": [
    $DRIVER_IPS
  ],
  "hostname": "$HOSTNAME"
}
EOF

# remove everything from the run/ directory
find run/ -mindepth 1 -delete

if [ -n "$FORCE_LASTPASS" -o \( -z "$SKIP_LASTPASS" -a "$SHCONFIG_ENV_TYPE" != "dev" \) ]
then
    # several scripts needed such as shared_functions2.sh, so compile everything that can compile:
    python3.10 bin/compile_scripts.py --ignore-undefined "src/$SHCONFIG_APP_TYPE/" vars/ run/
    . run/lastpass.sh
fi

######################################################
# compile the scripts, set perms, and run driver3.sh #
######################################################

install -m 0700 -d run
python3.10 bin/compile_scripts.py "src/$SHCONFIG_APP_TYPE/" vars/ run/

find run/ -name '*.sh' -exec chmod u+x {} \;

cd run
exec ./driver3.sh
