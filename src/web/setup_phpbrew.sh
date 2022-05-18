#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

export PHPBREW_HOME="{{php_dir}}"
export PHPBREW_ROOT="{{php_dir}}"

# 2020-07-07 jhb - Intentional adding of // to keep phpbrew from
# removing phpbrew from path when running `phpbrew use`
export PATH="$PATH:/{{php_dir}}/bin"

force_local_yum php
force_local_yum php-devel
force_local_yum php-pear

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
local_yum libsodium-devel


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

# 2021-06-11 jhb - Changing this so you have to run FORCE_PHPBREW;
# phpbrew update was taking way too long
if [ -n "$FORCE_PHPBREW_UPDATE" ]
then
    # TODO ideally this check would only be done on exception
    log_output local1.debug "Checking for phpbrew updates..."
    # Make sure we have all known versions:
    if ! [ -e "{{php_dir}}/distfiles/php-5.6.40.tar.bz2" ]
    then
	phpbrew_fn update --old >/dev/null
    else
	phpbrew_fn update >/dev/null
    fi
    phpbrew_fn self-update >/dev/null
    touch "{{driver_vardir}}/phpbrew-check"
fi

log_output local1.debug "Making sure phpbrew's internal version is installed"
if ! [ -e "{{php_dir}}/php/phpbrew-{{php_php_version}}/bin/php" ]
then
    phpbrew_fn install --name="phpbrew-{{php_php_version}}" {{php_php_version}} {{php_php_variant}} -- {{driver_php_buildoptions}}
fi

if ! [ -e "{{php_dir}}/modules/composer.phar" ]
then
    log_output local1.debug "Installing composer.phar"
    pushd "{{driver_builddir}}" >/dev/null
    curl -o composer-setup.php https://getcomposer.org/installer
    mkdir -p "{{php_dir}}/modules"
    php composer-setup.php --install-dir="{{php_dir}}/modules"
    popd
fi
