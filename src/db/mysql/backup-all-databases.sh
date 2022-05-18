#!/bin/bash
PATH=/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
set -e				# exit on error

mkdir -p "{{driver_backupdir}}/mysql"
cd "{{driver_backupdir}}/mysql"

# backup all db's on mysql:3306
mysqldump --defaults-extra-file="{{driver_rundir}}/mysql/backup.cnf" \
	  --single-transaction \
	  --max-allowed-packet=512M \
	  --result-file="backup-all-databases.sql" \
	  -f --port=3306 --all-databases --flush-logs --events --routines --triggers --opt

# -f will overwrite the previous backup. This will only run if there's
# no error.
gzip -f backup-all-databases.sql
