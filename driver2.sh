#!/bin/bash
# This file is called `driver2.sh` and is called by `driver.sh` so
# that it can be updated via a `git pull` from `driver.sh`.
#
# Checks for several environment variables. Sets some hackish
# variables such as $CENTOS_VERSION (assumes we're on centos) and
# $DRIVER_PHPBUILDOPTIONS (big hack).
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

# Need Python virtualenv set up for compiling scripts:
. ./python_venv.sh

####################################
# read/check environment variables #
####################################

if [ -e "env.sh" ]
then
    . ./env.sh
fi

if [ -z "$SHCONFIG_OS_BASE" ]
then
    log_output local1.error "SHCONFIG_OS_BASE not set; set to '/' or another path"
    exit 1
fi

if [ -z "$SHCONFIG_EMAIL" ]
then
    log_output local1.error "SHCONFIG_EMAIL not set; set to email address for cron jobs"
    exit 1
fi

if [ -z "$SHCONFIG_DBSERVER" -o -z "$SHCONFIG_WEBSERVER" ]
then
    log_output local1.error "SHCONFIG_DBSERVER and SHCONFIG_WEBSERVER must be set"
    exit 1
fi

if CENTOS_VERSION=$(rpm --eval '%{centos_ver}') >/dev/null 2>&1
then
    export DRIVER_IMAGEDIR="$DRIVER_DIR/image/centos${CENTOS_VERSION}"
else
    export DRIVER_IMAGEDIR="$DRIVER_DIR/image/unknown"
fi

export DRIVER_PHPBUILDOPTIONS="--with-libdir=lib64 --with-mcrypt='$SHCONFIG_OS_BASE/usr' --with-tidy='$SHCONFIG_OS_BASE/usr' --without-libzip"


if [ "$SHCONFIG_APP_TYPE" != "web" -a "$SHCONFIG_APP_TYPE" != "db" ]
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
  "os_base": "$SHCONFIG_OS_BASE",
  "email": "$SHCONFIG_EMAIL",
  "dbserver": "$SHCONFIG_DBSERVER",
  "webserver": "$SHCONFIG_WEBSERVER"
}
EOF

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
  "imagedir": "$DRIVER_IMAGEDIR",
  "builddir": "$DRIVER_DIR/build",
  "user": "$DRIVER_USER",
  "group": "${GROUPS[0]}",
  "php_buildoptions": "$DRIVER_PHPBUILDOPTIONS"
}
EOF

if [ -n "$FORCE_LASTPASS" -o \( -z "$SKIP_LASTPASS" -a "$SHCONFIG_ENV_TYPE" != "dev" \) ]
then
    # several scripts needed such as shared_functions2.sh, so compile everything that can compile:
    python bin/compile_scripts.py --ignore-undefined src/ vars/ run/
    . run/lastpass.sh
fi

######################################################
# compile the scripts, set perms, and run driver3.sh #
######################################################

install -m 0700 -d run
python bin/compile_scripts.py src/ vars/ run/

find run/ -name '*.sh' -exec chmod u+x {} \;

cd run
exec ./driver3.sh
