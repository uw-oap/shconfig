. ../shared_functions.sh

function file_md5_equal {
    FILE_A=$1
    FILE_B=$2

    FILE_A_MD5SUM=$(md5sum "$FILE_A" | cut -d' ' -f1)
    FILE_B_MD5SUM=$(md5sum "$FILE_B" | cut -d' ' -f1)
    [ "$FILE_A_MD5SUM" == "$FILE_B_MD5SUM" ]
}

function install_git_repo {
    # $1 - git branch
    # $2 - git repo
    # $3 - dest directory
    # $4 - rsync opts e.g. to ignore files
    # $5 - tar options e.g. to ignore files
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

	if [ -n "{{secrets_slack_webhook_pass}}" ]
	then
	    curl -X POST -s -H 'Content-type: application/json' --data "{\"text\":\"Deployed $REPO_NAME update to $(hostname)\"}" "{{secrets_slack_webhook_pass}}" > /dev/null
	fi
	rm "{{driver_vardir}}/$REPO_NAME-update"
    else
	log_output local1.debug "No update needed"
    fi
}


function set_web_restart_needed {
    touch "{{driver_vardir}}/httpd-restart"
}

function install_conf {
    SRC=$1
    TARGET=$2
    if [ "x$SRC" == "x" -o "x$TARGET" == "x" ]
    then
	log_output local1.crit "Need to pass src and target to install_conf"
	exit 1
    fi
    if [ ! -e "$TARGET" ]
    then
	set_web_restart_needed
    elif ! file_md5_equal "$SRC" "$TARGET"
    then
	set_web_restart_needed
    fi
    install -CD -m 0444 "$SRC" "$TARGET"
}

function sudo_install_conf {
    SRC=$1
    TARGET=$2
    if [ "x$SRC" == "x" -o "x$TARGET" == "x" ]
    then
	log_output local1.crit "Need to pass src and target to install_conf"
	exit 1
    fi
    if [ ! -e "$TARGET" ]
    then
	set_web_restart_needed
    elif ! file_md5_equal "$SRC" "$TARGET"
    then
	set_web_restart_needed
    fi
    sudo install -CD -m 0444 "$SRC" "$TARGET"
}


function set_rt_install_needed {
    touch "{{driver_vardir}}/rt-install"
}

function set_rt_autoassign_install_needed {
    touch "{{driver_vardir}}/rt-autoassign-install"
}

function install_apache {
    if [ "{{shconfig_env_type}}" == "dev" ]
    then
	INSTALL_CHOWN=""
    else
	INSTALL_CHOWN="-o {{driver_user}} -g {{apache_group}}"
    fi
    install $INSTALL_CHOWN "$@"
}

function install_driver {
    if [ "{{shconfig_env_type}}" == "dev" ]
    then
	INSTALL_CHOWN=""
    else
	INSTALL_CHOWN="-o {{driver_user}} -g {{driver_group}}"
    fi
    install $INSTALL_CHOWN "$@"
}

function patch_if_needed {
    PATCH_FILE="$1"

    # Has the patch been applied yet?
    if patch -p0 -s -f --dry-run < "$PATCH_FILE" > /dev/null
    then
	# No; patch it
	patch -p0 -s -f < "$PATCH_FILE"
    fi
    
}
