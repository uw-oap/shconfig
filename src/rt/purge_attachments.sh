#!/bin/sh
PATH=/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
set -e

MyUSER="{{secrets_rt_db_user}}"
MyPASS="{{secrets_rt_db_pass}}"
MyDB="{{rt_db_name}}"
MyHOST="localhost"

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$SCRIPT_DIR"

mysql -u $MyUSER -h $MyHOST "-p$MyPASS" $MyDB < ./purge_attachments.sql
