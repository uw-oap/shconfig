#!/bin/sh
PATH=/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
set -e

MyDB="{{rt_db_name}}"

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$SCRIPT_DIR"

mysql --defaults-extra-file="{{driver_rundir}}/mysql/rt.cnf" $MyDB < ./purge_attachments.sql
