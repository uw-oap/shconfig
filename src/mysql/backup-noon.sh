#!/bin/bash
set -e
BACKUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$BACKUP_DIR"
. ./backup_functions.sh

# DO NOT BACKUP these databases
SKIP="{{mysql_backup_noon_excludedbs}}"
 
backup_databases "$SKIP"
