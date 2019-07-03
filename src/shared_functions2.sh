. ../shared_functions.sh

function rpm_dependencies {
    RPM_DEPENDENCIES="$(yum deplist --config="{{driver_rundir}}/os/yum.conf" --enablerepo=epel $1 | perl -lne 'print $1 if /provider: (\S+?)(\.x86_64|\.i686)?\s/i' | sort | uniq)"
    echo "$RPM_DEPENDENCIES"
}

function rpm_is_locally_installed {
    FIRST_FILE="$(repoquery --archlist=x86_64 --config="{{driver_rundir}}/os/yum.conf" --enablerepo=epel -l $1 2>/dev/null | head -1)"
    if [ -z "$FIRST_FILE" ]
    then
	FIRST_FILE="$(repoquery --config="{{driver_rundir}}/os/yum.conf" --enablerepo=epel -l $1 | head -1)"
    fi
    if [ -z "$FIRST_FILE" ]
    then
	log_output local1.crit "Could not repoquery $1"
	exit 1
    fi
       
    if [ -e "{{shconfig_os_base}}/$FIRST_FILE" ]
    then
	return 0
    else
	return 1
    fi
}

function rpm_is_installed {
    # TODO x86_64 hardcoded:
    if rpm -q "$1" > /dev/null
    then
	return 0
    else
	rpm_is_locally_installed $1
   fi
}


function install_local_rpm {
    log_output local1.info "RPM $1 not installed; installing"

    seen_dependencies="$2"

    for rpm in $(rpm_dependencies "$1")
    do
	if [[ $seen_dependencies == *"#$rpm#"* ]]
	then
	    log_output local1.debug "Already seen $rpm in dependencies; skipping"
	else
	    log_output local1.debug "Checking on dependency $rpm for $1"
	    local_yum $rpm "$seen_dependencies#$1#"
	fi
    done

    log_output local1.debug "Downloading RPM..."
    pushd "{{driver_builddir}}" >/dev/null

    # Need $1-*.rpm to evaluate to nothing
    shopt -s nullglob > /dev/null
    rm -f $1-*.rpm

    yumdownloader --arch=x86_64 -x \*i686 --config="{{driver_rundir}}/os/yum.conf" --enablerepo=epel $1

    # This reads through the RPMs to make sure the RPM name is the same:
    for i in *.rpm
    do
        RPM_NAME=$(rpm -qp $i --qf "%{NAME}")
        if [ "$RPM_NAME" == "$1" ]
        then
            PACKAGE=$i
        fi
    done

    PACKAGE=$1-*.rpm
    if [ -z "$PACKAGE" ]
    then
	log_output local1.crit "Could not download RPM $1; exiting"
	exit 1
    fi
    log_output local1.debug "Extracting RPM to {{shconfig_os_base}}..."
    mkdir -p "{{shconfig_os_base}}"
    rpm2cpio $PACKAGE | ( cd "{{shconfig_os_base}}" && cpio -idmv )

    if [ "$1" == "mariadb-devel" ]
    then
        log_output local1.debug "Building mysql_config for mariadb-devel"
        mkdir -p "{{shconfig_os_base}}/usr/bin"
        cp "{{shconfig_os_base}}/usr/lib64/mysql/mysql_config" "{{shconfig_os_base}}/usr/bin/"
    fi

    popd >/dev/null

    shopt nullglob > /dev/null

    if ! rpm_is_locally_installed $1
    then
	log_output local1.crit "Could not install RPM $1; exiting"
	exit 1
    fi

}

function force_local_yum {
    log_output local1.debug "Checking for local RPM $1"
    if rpm_is_locally_installed $1
    then
	log_output local1.debug "RPM $1 is locally installed"
    else
	log_output local1.debug "Installing $1"
	install_local_rpm $1 "$2"
    fi
}

function local_yum {
    log_output local1.debug "local_yum for $1"
    if rpm_is_installed $1
    then
	log_output local1.debug "RPM $1 is installed"
    else
	install_local_rpm $1
    fi
}

function phpbrew_fn {
    if [ -e "{{apconfig_os_base}}/usr/bin/php" ]
    then
	# we're using a local php to bootstrap. yay
        "{{apconfig_os_base}}/usr/bin/php" -c "{{driver_rundir}}/php/php.ini" "/data/phpbrew/bin/phpbrew" "$@"
    else
        "{{php_phpbrew}}" "$@"
    fi
}

function install_git_repo {
    # $1 - git branch
    # $2 - git repo
    # $3 - dest directory
    # $4 - rsync opts e.g. to ignore files
    GIT_BRANCH=$1
    GIT_REPO=$2
    DEST_DIR=$3
    RSYNC_OPTS=$4
    TAR_OPTS=$5

    REPO_NAME=${GIT_REPO##*/}		# This removes everything up through the last /

    log_output local1.debug "Checking git repo $REPO_NAME branch $GIT_BRANCH"

    if [ -z "$REPO_NAME" ]
    then
	log_output local1.crit "Specified repository doesn't have a name"
	exit 1
    fi

    REPO_BUILD_DIR="{{driver_builddir}}/$REPO_NAME"

    # TODO detect GIT_REPO changes
    if [ -n "$FORCE_UPDATE" ]
    then
	# delete build directory. This helps with the GIT_REPO changing
	if [ "$REPO_BUILD_DIR" -ef "/" ]
	then
	    log_output local1.crit "Somehow REPO_BUILD_DIR is /; bailing to keep from rm -rf /"
	    exit 1
	fi
	log_output local1.debug "FORCE_UPDATE set; erasing $REPO_BUILD_DIR"
	rm -rf "$REPO_BUILD_DIR"
    fi

    if ! [ -e "$REPO_BUILD_DIR" ]
    then
	log_output local1.debug "Build directory doesn't exist; building"
	GIT_SSL_NO_VERIFY=true git clone $GIT_QUIET -b $GIT_BRANCH "$GIT_REPO" "{{driver_builddir}}/$REPO_NAME"
	touch "{{driver_vardir}}/$REPO_NAME-update"
    else
	log_output local1.debug "Build directory exists; fetching"
	pushd "$REPO_BUILD_DIR" >/dev/null
	git fetch $GIT_QUIET --all

	log_output local1.debug "Is an update needed?"
	if ! [ -e "$DEST_DIR" ]
	then
	    touch "{{driver_vardir}}/$REPO_NAME-update"
	elif [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/$GIT_BRANCH)" ]
	then
	    touch "{{driver_vardir}}/$REPO_NAME-update"
	fi

	popd >/dev/null
    fi

    if [ -e "{{driver_vardir}}/$REPO_NAME-update" ]
    then
	log_output local1.info "Update/checkout needed for $REPO_NAME"
	pushd "$REPO_BUILD_DIR" >/dev/null

	git checkout $GIT_QUIET -f $GIT_BRANCH
	git pull $GIT_QUIET
	git submodule $GIT_QUIET sync
	git submodule $GIT_QUIET update --init --recursive
	popd > /dev/null

	log_output local1.debug "Does the destination exist?"
	if [ -e "$DEST_DIR" ]
	then
	    log_output local1.debug "Yes, the destination exists"
	    # make a backup of the current prod env:
	    DEST_DIR_AS_FILE=${DEST_DIR//\//_}
	    DATETIME=$(date "+%Y-%m-%d-%H%M%S")
	    BACKUP_FILEPATH="{{driver_backupdir}}/$DEST_DIR_AS_FILE-$DATETIME.tgz"
	    if [ -e "$BACKUP_FILE" ]
	    then
		log_output local1.crit "Somehow $BACKUP_FILE already exists; bailing"
		exit 1
	    fi
	    log_output local1.debug "Backing up '$DEST_DIR' to $BACKUP_FILEPATH"
	    tar $TAR_OPTS -czf "$BACKUP_FILEPATH" "$DEST_DIR"

	    # WARNING: complicated shell piping
	    # 
	    # 1. find all files in the backup directory more than 15 days old
	    # 
	    # 2. look for backups matching this backup's name
	    # 
	    # 3. sort these asciibetically. this should put the oldest
	    # files at the top based on our naming parameters
	    # 
	    # 4. get all but the last three (head -n-3)
	    # 
	    # 5. pass these to xargs to remove
	    #
	    log_output local1.debug "Purging old backups"
	    find "{{driver_backupdir}}" -type f -mtime +15 | \
		grep "$DEST_DIR_AS_FILE" | sort | head -n-3 | \
		xargs -I {} rm "{}"
	fi

	log_output local1.debug "Going to rsync..."
	# Do not expand globs:
	set -f
	if [ -z "$DEBUG" ]
	then
	    rsync -az --exclude '.git' $RSYNC_OPTS --delete "$REPO_BUILD_DIR/" "$DEST_DIR/"
	else
	    rsync -avz --exclude '.git' $RSYNC_OPTS --delete "$REPO_BUILD_DIR/" "$DEST_DIR/"
	fi
	set +f

	rm "{{driver_vardir}}/$REPO_NAME-update"
    else
	log_output local1.debug "No update needed"
    fi
}


function file_md5_equal {
    FILE_A=$1
    FILE_B=$2

    FILE_A_MD5SUM=$(md5sum "$FILE_A" | cut -d' ' -f1)
    FILE_B_MD5SUM=$(md5sum "$FILE_B" | cut -d' ' -f1)
    [ "$FILE_A_MD5SUM" == "$FILE_B_MD5SUM" ]
}


function set_web_restart_needed {
    touch "{{driver_vardir}}/httpd-restart"
}

function set_db_restart_needed {
    touch "{{driver_vardir}}/mariadb-restart"
}

function set_rt_install_needed {
    touch "{{driver_vardir}}/rt-install"
}

function set_rt_autoassign_install_needed {
    touch "{{driver_vardir}}/rt-autoassign-install"
}
