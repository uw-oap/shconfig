#!/bin/sh
# system php is in /usr/local/bin which is not in the default PATH for
# some reason:
PATH=/bin:/sbin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

exec php "$@"
