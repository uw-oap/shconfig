#!/bin/bash
PATH=/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
set -e

function remove_old_backups {
    # This relies on alphabetical order.
    # 
    # head -n-3 means "all but the last 3"
    BACKUPS_TO_REMOVE=$(ls $1.*.gz | sort | head -n-3)
    for i in $BACKUPS_TO_REMOVE
    do
	rm $i
    done
}

function backup_databases {
    SKIP="$1"
    
    # FIXME implement a database backup here, to backup all databases
    # unless named by SKIP
}
