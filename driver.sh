#!/bin/bash
# The program that starts it all. driver.sh sets a couple of key
# variables, makes sure we're in the right directory, gets the latest
# git commit for whatever branch we're one, and then runs driver2.sh
set -e
export DRIVER_RUNNING="YES"
export DRIVER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DRIVER_DIR"
chmod 700 "$DRIVER_DIR"

if [ -z "$DEBUG" ]
then
    export GIT_QUIET="--quiet"
else
    export GIT_QUIET=""
fi

. ./shared_functions.sh

if [ -z "$SKIP_GITPULL" ]
then
    log_output local1.debug "Running git pull"
    git pull $GIT_QUIET
fi

exec ./driver2.sh
