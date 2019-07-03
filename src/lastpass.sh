#!/bin/bash
#
# This file populates vars/secrets.json with data from lastpass, looking at the lastpass names.
# Name starts with 'stg_' ? Pull it in if we're in staging.
# Name starts with 'prod_' ? Pull it in if we're in prod.
pushd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null
. ./shared_functions2.sh
set -e

local_yum jq
local_yum lastpass-cli
PATH="$PATH:{{shconfig_os_base}}/usr/bin"
export LD_LIBRARY_PATH="{{shconfig_os_base}}/usr/lib64"
export XDG_RUNTIME_DIR="$HOME"

mkdir -p ~/.config ~/.local/share
echo -n "Enter your lastpass username: "
read LPASS_USERNAME

# use the lastpass native "UI"
export LPASS_DISABLE_PINENTRY=1
lpass login "$LPASS_USERNAME"

if [  "$SHCONFIG_ENV_TYPE" == "stg" ]
then
    # the [4:] is because "stg_" is 4 characters:
    lpass show -j -x --basic-regexp '^stg_' | jq  '.[] | if (.username|length)>0 then {(.name[4:]+"_user"): .username, (.name[4:]+"_pass"): .password} else {} end' | jq -s add > "{{driver_dir}}/vars/secrets.json"
    lpass show -j -x --basic-regexp '^stg_' | jq  '.[] | if (.username|length)==0 then {(.name[4:]): .note} else {} end' | jq -s add > "{{driver_dir}}/vars/secretnotes.json"
    

elif [ "$SHCONFIG_ENV_TYPE" == "prd" ]
then
    # the [5:] is because "prod_" is 5 characters
    lpass show -j -x --basic-regexp '^prod_' | jq  '.[] | if (.username|length)>0 then {(.name[5:]+"_user"): .username, (.name[5:]+"_pass"): .password} else {} end' | jq -s add > "{{driver_dir}}/vars/secrets.json"
    lpass show -j -x --basic-regexp '^prod_' | jq  '.[] | if (.username|length)==0 then {(.name[5:]): .note} else {} end' | jq -s add > "{{driver_dir}}/vars/secretnotes.json"

else
    log_output local1.warning "lastpass only creates a file when SHCONFIG_ENV_TYPE is 'stg' or 'prd'"
fi

# TODO it would be nice to check here and make sure we got all the
# variables we're supposed to have.


lpass logout -f
popd
