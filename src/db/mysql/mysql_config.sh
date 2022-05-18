#!/bin/bash
"{{shconfig_os_base}}/usr/bin/mysql_config" $@ | perl -pe 's^(/usr|/var)^{{shconfig_os_base}}$1^g'
