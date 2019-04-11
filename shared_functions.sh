function log_output {
    logger -p "$1" "$2"
    level=${1##*.}

    # skip DEBUG level unless $DEBUG set
    if [ "$level" == "debug" -a -z "$DEBUG" ]
    then
	return
    fi
    if ! [ -z "$DRIVER_DIR" ]
    then
	mkdir -p "$DRIVER_DIR/var/log"
	echo "$(date +"%Y-%m-%d %H:%M:%S") $1 $2" >> "$DRIVER_DIR/var/log/shconfig.log"
    fi
    >&2 echo "$2"
}

function assert_driver {
    if [ "$DRIVER_RUNNING" != "YES" ]
    then
	log_output local1.error "This script was designed to be called from driver; exiting"
	exit 1
    fi
}
