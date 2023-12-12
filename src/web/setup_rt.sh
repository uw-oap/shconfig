#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting setup_rt.sh"

############
# Build RT #
############

export PERLBREW_ROOT="{{perlbrew_dir}}"
RT_PERL_NAME="perl-{{rt_perlversion}}-rt{{rt_version}}"

log_output local1.debug "Making sure perlbrew is installed..."
if ! [ -e "{{perlbrew_dir}}/bin/perlbrew" ]
then
    log_output local1.debug "Making sure perlbrew is installed"
    install -CD -o {{driver_user}} -g {{driver_group}} -m 0755 -d "{{perlbrew_dir}}"
    ./rt/install_perlbrew.sh
fi

# This defines `perlbrew` as a bash function:
source "{{perlbrew_dir}}/etc/bashrc"

log_output local1.debug "Making sure cpanm is installed"
if ! [ -e "{{perlbrew_dir}}/bin/cpanm" ]
then
    perlbrew install-cpanm
fi


log_output local1.debug "Making sure perl for RT is installed + RT is installed"
if ! [ -e "{{perlbrew_dir}}/perls/$RT_PERL_NAME/bin/perl" ]
then
   set_rt_install_needed
elif ! [ -e "{{rt_dir}}/bin/rt" ]
then
    set_rt_install_needed
fi

if [ -e "{{driver_vardir}}/rt-install" ]
then
    log_output local1.debug "Need to build RT and/or Perl"

    if ! [ -e "{{perlbrew_dir}}/perls/$RT_PERL_NAME/bin/perl" ]
    then
	log_output local1.info "Installing Perl from source..."
	perlbrew install --as $RT_PERL_NAME perl-{{rt_perlversion}}
    fi
fi

# This makes sure cpanm installs to the correct Perl:
perlbrew use $RT_PERL_NAME

if [ -e "{{driver_vardir}}/rt-install" ]
then
    log_output local1.debug "Checking on RT build dependencies"

    # local_yum expat-devel
    # local_yum openssl-devel
    # local_yum mariadb-devel

    # cpanm ExtUtils/Manifest.pm
    cpanm Locale::PO

    # 2020-07-09 jhb - For some reason these aren't being installed by
    # make fixdeps on centos 7
    if ! perl -MLog::Any -e1 2>/dev/null
    then
	cpanm -f Log::Any
    fi

    cpanm HTML::Mason
    cpanm HTML::Mason::PSGIHandler


    # DBD::mysql relies on mariadb-libs and mariadb-devel, which is a huge
    # headache because UW-IT does not deliver mariadb-devel, but they do
    # deliver mariadb-libs, but mariadb-devel does not play well without
    # mariadb-libs

    # export DBD_MYSQL_CONFIG="{{driver_rundir}}/mysql/mysql_config.sh"
    # force_local_yum mariadb-libs
    # force_local_yum mariadb-devel
    cpanm DBD::mysql

    mkdir -p "{{driver_builddir}}"
    # -- PUSHD vv
    pushd "{{driver_builddir}}" >/dev/null

    if ! [ -e "rt-{{rt_version}}" ]
    then
	log_output local1.info "Downloading RT"
	curl -O https://download.bestpractical.com/pub/rt/release/rt-{{rt_version}}.tar.gz
	tar xzvf rt-{{rt_version}}.tar.gz
    fi

    cd rt-{{rt_version}}
    log_output local1.info "Configuring RT"
    export PERL="$(which perl)"
    ./configure  --disable-gpg --prefix={{rt_dir}} --with-my-user-group --with-web-user={{apache_user}} --with-web-group={{apache_group}} --libdir=/os/base/usr/lib64
    RT_FIX_DEPS_CMD=cpanm make fixdeps
    if [ ! -e "etc/schema.mysql.bak" ]
    then
	perl -i.bak -pe 's|\bGroups\b|`Groups`|g' etc/schema.mysql
    fi
    if [ ! -e "lib/RT/Principal.pm.bak" ]
    then
	perl -i.bak -pe 's|Groups, Principals|`Groups`, Principals|' lib/RT/Principal.pm
    fi
    patch_if_needed "{{driver_rundir}}/rt/LoadFromSQL.patch"
    patch_if_needed "{{driver_rundir}}/rt/UTF8MB4.patch"

    popd > /dev/null
    # -- POPD ^^
fi # if rt is not installed already

# if RT is installed already...
if [ -e "{{rt_dir}}/bin/rt" ]
then
    if ! [ -e "{{rt_dir}}/local/plugins/RT-Extension-AutomaticAssignment" ]
    then
	log_output local1.debug "Need to install RT::Extension::AutomaticAssignment"
	set_rt_autoassign_install_needed
	# 1.0.0+ is for RT5+
	cpanm -q --showdeps RT::Extension::AutomaticAssignment~"<1.0.0" | xargs cpanm
	cpanm Module::Install
	cpanm Business::Hours
	EXTENSION_PATH=$(echo 'pwd' | cpanm -q --look RT::Extension::AutomaticAssignment~"<1.0.0")
	EXTENSION_DIR="RT-Extension-AutomaticAssignment"
	if ! [ -e "{{driver_builddir}}/$EXTENSION_DIR" ]
	then
	    mv "$EXTENSION_PATH" "{{driver_builddir}}/$EXTENSION_DIR"
	fi
	pushd "{{driver_builddir}}/$EXTENSION_DIR"
	RTHOME="{{rt_dir}}" perl Makefile.PL
	make
	popd
    fi
fi

if ! [ -e "{{rt_procmail_file}}" ]
then
    log_output local1.error "Procmail file {{rt_procmail_file}} does not exist"
elif ! file_md5_equal rt/procmailrc "{{rt_procmail_file}}"
then
    log_output local1.debug "{{rt_procmail_file}} is different from rt/procmailrc"
    log_output local1.info "Please update {{rt_procmail_file}} with the contents of rt/procmailrc"
fi	

if ! [ -e "{{rt_procmail_blocklist}}" ]
then
    log_output local1.error "Procmail file {{rt_procmail_blocklist}} does not exist"
    log_output local1.error "Please create it manually using the secret file"
fi	

if [ -e "{{rt_dir}}/lib/RT/" ]
then
    pushd "{{rt_dir}}" > /dev/null

    patch_if_needed "{{driver_rundir}}/rt/LoadFromSQL.patch"
    patch_if_needed "{{driver_rundir}}/rt/UTF8MB4.patch"

    popd > /dev/null
fi

###########################
# Ensure RT is configured #
###########################

log_output local1.debug "Installing RT config files..."
install_apache -CD -d "{{rt_dir}}/etc/"
install_apache -CD -m 0770 -d "{{rt_dir}}/var"
install_apache -CD -m 0770 -d "{{rt_dir}}/var/data/RT-Shredder"
install_apache -CD -m 0750 -d "{{rt_dir}}/var/attachments"
install_apache -C -o {{driver_user}} -g {{apache_group}} -m 0440 rt/RT_SiteConfig.pm "{{rt_dir}}/etc/RT_SiteConfig.pm"
install_apache -CD -o {{driver_user}} -g {{apache_group}} -m 0444 rt/ckeditor_config.js "{{rt_dir}}/local/static/RichText/config.js"
install -C -m 0700 rt/shred.sh "{{driver_bindir}}/rt-shred.sh"
install -C -m 0400 rt/acl.mysql "{{rt_dir}}/etc/acl.mysql"
