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
    if ! rpm -q perl
    then
	log_output local1.crit "Perl not installed; can't build perlbrew"
	exit 1
    fi
    
    log_output local1.debug "Making sure perlbrew is installed"
    install -CD -o {{driver_user}} -g {{driver_group}} -m 0755 -d "{{perlbrew_dir}}"
    ./install_perlbrew.sh
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
	log_output local1.debug "Need to build Perl"
	if ! rpm -q install patch gcc
	then
	    log_output local1.crit "install, patch, gcc need to be installed"
	fi

	log_output local1.info "Installing Perl from source..."
	perlbrew install --as $RT_PERL_NAME perl-{{rt_perlversion}}
    fi
fi

# This makes sure cpanm installs to the correct Perl:
perlbrew use $RT_PERL_NAME

if [ -e "{{driver_vardir}}/rt-install" ]
then
    log_output local1.debug "Checking on RT build dependencies"

    local_yum expat-devel
    local_yum openssl-devel
    local_yum mariadb-devel

    cpanm ExtUtils/Manifest.pm
    cpanm Locale/PO.pm

    # MooX-late 0.015 has a test error. Force install if not installed
    if ! perl -MMoo -MMooX::late -e1 2>/dev/null
    then
	cpanm -f MooX/late.pm
    fi

    if ! perl -MHTTP::Headers::Fast -e1 2>/dev/null
    then
	cpanm -f HTTP::Headers::Fast
    fi

    # DBD::mysql relies on mariadb-libs and mariadb-devel, but the OS
    # may have one installed but not the other.
    export DBD_MYSQL_CONFIG="{{driver_rundir}}/mysql/mysql_config.sh"
    force_local_yum mariadb-libs
    force_local_yum mariadb-devel
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
    ./configure --prefix={{rt_dir}} --with-my-user-group --with-web-user={{apache_user}} --with-web-group={{apache_group}} --libdir=/os/base/usr/lib64
    RT_FIX_DEPS_CMD=cpanm make fixdeps

    popd > /dev/null
    # -- POPD ^^
fi # if rt is not installed already

# TODO maybe bail at this point and require that RT be installed before continuing??

# FIXME this requires driver being run *twice* to happen.
# Maybe this should be in the `local` directory intsead of the `share` directory?
if [ -e "{{rt_dir}}/share/static/RichText" ]
then
    if ! grep "4.11.3" "{{rt_dir}}/share/static/RichText/ckeditor.js" > /dev/null
    then
	pushd "{{driver_builddir}}" >/dev/null
	rm -rf ckeditor
	curl -O https://download.cksource.com/CKEditor/CKEditor/CKEditor%204.11.3/ckeditor_4.11.3_standard.zip
	unzip ckeditor_4.11.3_standard.zip
	mv "{{rt_dir}}/share/static/RichText" "$(mktemp -u {{rt_dir}}/share/static/RichText-$(date +%Y%m%d)-XXX)"
	rsync -az ckeditor/ "{{rt_dir}}/share/static/RichText/"
	chgrp -R "{{apache_group}}" "{{rt_dir}}/share/static/RichText/"
	popd > /dev/null
    fi
fi

# if RT is installed already...
if [ -e "{{rt_dir}}/bin/rt" ]
then
    if ! [ -e "{{rt_dir}}/local/plugins/RT-Extension-AutomaticAssignment" ]
    then
	log_output local1.debug "Need to install RT::Extension::AutomaticAssignment"
	set_rt_autoassign_install_needed
	cpanm -q --showdeps RT::Extension::AutomaticAssignment | xargs cpanm
	cpanm Module::Install
	cpanm Business::Hours
	EXTENSION_PATH=$(echo 'pwd' | cpanm -q --look RT::Extension::AutomaticAssignment)
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

log_output local1.debug "Checking on procmail..."
local_yum procmail

if ! [ -e "{{rt_procmail_file}}" ]
then
    log_output local1.error "Procmail file {{rt_procmail_file}} does not exist"
elif ! file_md5_equal rt/procmailrc "{{rt_procmail_file}}"
then
    log_output local1.debug "{{rt_procmail_file}} is different from rt/procmailrc"
    log_output local1.info "Please update {{rt_procmail_file}} with the contents of rt/procmailrc"
fi	

###########################
# Ensure RT is configured #
###########################

log_output local1.debug "Installing RT config files..."
install -CD -o {{driver_user}} -g {{apache_group}} -d "{{rt_dir}}/etc/"
install -CD -o {{driver_user}} -g {{apache_group}} -m 0770 -d "{{rt_dir}}/var"
install -CD -o {{driver_user}} -g {{apache_group}} -m 0770 -d "{{rt_dir}}/var/data/RT-Shredder"
install -CD -o {{driver_user}} -g {{apache_group}} -m 0750 -d "{{rt_dir}}/var/attachments"
install -C -o {{driver_user}} -g {{apache_group}} -m 0440 rt/RT_SiteConfig.pm "{{rt_dir}}/etc/RT_SiteConfig.pm"
install -CD -o {{driver_user}} -g {{apache_group}} -m 0444 rt/ckeditor_config.js "{{rt_dir}}/share/static/RichText/config.js"
install -CD -o {{driver_user}} -g {{apache_group}} -m 0444 rt/contents.css "{{rt_dir}}/share/static/RichText/contents.css"
install -C -m 0700 rt/shred.sh "{{driver_bindir}}/rt-shred.sh"
