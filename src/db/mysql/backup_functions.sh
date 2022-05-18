#!/bin/bash
# 2019-02-12 jhb: Updating the original backup script in lieu of creating a new one.
# ---
# Shell script to backup MySql database
# To backup Nysql databases file to /backup dir and later pick up by your
# script. You can skip few databases from backup too.
# For more info please see (Installation info):
# http://www.cyberciti.biz/nixcraft/vivek/blogger/2005/01/mysql-backup-script.html
# Last updated: Aug - 2005
# --------------------------------------------------------------------
# This is a free shell script under GNU GPL version 2.0 or above
# Copyright (C) 2004, 2005 nixCraft project
# Feedback/comment/suggestions : http://cyberciti.biz/fb/
# -------------------------------------------------------------------------
# This script is part of nixCraft shell script collection (NSSC)
# Visit http://bash.cyberciti.biz/ for more information.
# -------------------------------------------------------------------------
PATH=/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
set -e

ExportOPTS="-f --add-drop-database --opt --events  --routines --triggers --max_allowed_packet=512M"
 
# Main directory where backup will be stored
MBD="{{driver_backupdir}}/mysql"
mkdir -p "$MBD"
cd $MBD

# Get hostname
HOST="$(hostname)"
 
# Get data in yyyy-mm-dd format
NOW="$(date +"%F-%R")"
 
# File to store current backup file
FILE=""
# Store list of databases
DBS=""
 
# Get all database list first
DBS="$(mysql --defaults-extra-file="{{driver_rundir}}/mysql/backup.cnf" -Bse 'show databases')"

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
    IGGY="$1"
    
    for db in $DBS
    do
	skipdb=-1
	if [ "$IGGY" != "" ];
	then
	    for i in $IGGY
	    do
		[ "$db" == "$i" ] && skipdb=1 || :
	    done
	fi
	
	if [ "$skipdb" == "-1" ] ; then
	    FILE="$db.$NOW.$HOST.gz"
	    # do all inone job in pipe,
	    # connect to mysql using mysqldump for select mysql database
	    # and pipe it out to gz file in backup dir :)
            if mysqldump --defaults-extra-file="{{driver_rundir}}/mysql/backup.cnf" $ExportOPTS $db | gzip > $FILE
	    then
		remove_old_backups $db
	    else
		echo "command failed, sending email";
		mail -s "DataBase backup failed for ${db}" "{{shconfig_email}}" << END_MAIL
Database backup failed on ${HOST} for schema ${db} done ${NOW} .
END_MAIL
	    fi
	fi
    done
}
