#!/bin/bash

cd "{{rt_dir}}/var/data/RT-Shredder"

function shred_query {
    QUERY=$1
    # Shred tickets:
    MORE_TO_SHRED=1
    while [ "$MORE_TO_SHRED" == 1 ]
    do
	SHRED_OUTPUT_FILE=$("{{rt_dir}}/sbin/rt-shredder" --plugin "$QUERY" --force | perl -ne 'print $1 if /SQL dump file is .(.*).$/')
	if [ -s "$SHRED_OUTPUT_FILE" ]
	then
	    : # there's more to shred
	else
	    MORE_TO_SHRED=0
	fi
    done
}

shred_query "Tickets=query,Status = 'Deleted' AND LastUpdated < '30 days ago';limit,100"
shred_query "Users=no_ticket_transactions,1"


#
# Can't delete attachments directly, but you can
#   DELETE FROM Attachments where Filename IS NOT NULL and Created < '2016-01-01';
# and RT then doesn't have the attachment.
#


