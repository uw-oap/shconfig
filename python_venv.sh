#!/bin/bash
set -e
. ./shared_functions.sh

log_output local1.debug "Making sure Python 2.7 is installed"
if ! rpm -q python >/dev/null
then
    log_output local1.crit "Python 2.7 must be installed"
    exit 1
fi

log_output local1.debug "Making sure virtualenv is installed"
if ! rpm -q python-virtualenv >/dev/null
then
    log_output local1.crit "Python-virtualenv must be installed"
    exit 1
fi

log_output local1.debug "Making sure driver virtualenv exists"
export VIRTUALENV_ROOT=/data/virtualenv
if ! [ -e "$VIRTUALENV_ROOT" ]
then
    # build a minimal perl in /opt/perl5
    install -d "$VIRTUALENV_ROOT"
    virtualenv --python=python2.7 "$VIRTUALENV_ROOT/driver"
fi

log_output local1.debug "Making sure Python packages installed in driver"
# Now use the Python virtualenv:
source "$VIRTUALENV_ROOT/driver/bin/activate"
if ! pip list --format=legacy 2>/dev/null | grep -q Jinja2
then
    pip install jinja2
fi
