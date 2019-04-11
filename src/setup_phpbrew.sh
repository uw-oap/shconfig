#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

export PHPBREW_HOME="{{php_dir}}"
export PHPBREW_ROOT="{{php_dir}}"

local_yum php
local_yum php-devel
local_yum php-pear

if ! rpm -q make automake gcc gcc-c++ kernel-devel bzip2-devel yum-utils bison libxslt-devel pcre-devel libcurl-devel openldap-devel readline-devel >/dev/null
then
    log_output local1.crit "RPMs to build PHP are not installed"
    exit 1
fi

local_yum re2c
local_yum libmcrypt
local_yum libmcrypt-devel
local_yum libpqxx-devel
local_yum libgsasl-devel
local_yum libtidy-devel

if ! [ -e "{{php_dir}}/bin/phpbrew" ]
then
    log_output local1.debug "Installing phpbrew..."
    pushd "{{driver_builddir}}" >/dev/null
    curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew
    install -CD -m 0755 ./phpbrew "{{php_phpbrew}}"
    popd >/dev/null
fi

if ! [ -e "{{php_dir}}/bashrc" ]
then
    log_output local1.debug "Initializing phpbrew..."
    phpbrew_fn init
fi


source "{{php_dir}}/bashrc"
