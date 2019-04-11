#!/bin/bash
/data/os/usr/bin/mysql_config $@ | perl -pe 's^(/usr|/var)^{{shconfig_os_base}}$1^g'
