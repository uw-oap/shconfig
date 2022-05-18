#!/bin/bash
set -e
BACKUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$BACKUP_DIR"
. ./backup_functions.sh

# DO NOT BACKUP these databases
IGGY="{{mysql_backup_excludedbs}}"
 
backup_databases "$IGGY"
