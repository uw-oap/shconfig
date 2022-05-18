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
# 2019-03-07 jhb: This variable is set with `su2 apis` but not `su2 -
# apis`. Need to set it explicitly so that either way of running su2
# will work.
export XDG_RUNTIME_DIR="$HOME"

# LASTPASS_STEMS represents the lastpass entries to search for that
# start with this stem. For example, if `stg` is in LASTPASS_STEMS
# then we want to put any password starting with `stg_` into
# secrets.json/secretnotes.json
LASTPASS_STEMS=()

if [ "$SHCONFIG_ENV_TYPE" == "stg" ]
then
    LASTPASS_STEMS+=("stgall")
    if [ "$SHCONFIG_APP_TYPE" == "db" -o "$SHCONFIG_APP_TYPE" == "web" ]
    then
	LASTPASS_STEMS+=("stg")
    fi
    if [ "$SHCONFIG_APP_TYPE" == "db" -o "$SHCONFIG_APP_TYPE" == "wp" ]
    then
	LASTPASS_STEMS+=("stgwp")
    fi
fi

if [ "$SHCONFIG_ENV_TYPE" == "prd" ]
then
    LASTPASS_STEMS+=("prodall")
    if [ "$SHCONFIG_APP_TYPE" == "db" -o "$SHCONFIG_APP_TYPE" == "web" ]
    then
	LASTPASS_STEMS+=("prod")
    fi
    if [ "$SHCONFIG_APP_TYPE" == "db" -o "$SHCONFIG_APP_TYPE" == "wp" ]
    then
	LASTPASS_STEMS+=("prodwp")
    fi
fi

# jinja2 note - {# extra {{'s due to jinja2 interpolation #}
if (( ${{"{#LASTPASS_STEMS[@]}"}} > 0 ))
then
    mkdir -p ~/.config ~/.local/share
    echo -n "Enter your lastpass username: "
    read LPASS_USERNAME

    # 2019-02-11: `apis` was not able to use pinentry for some reason
    export LPASS_DISABLE_PINENTRY=1
    lpass login "$LPASS_USERNAME"

    echo "" > "{{driver_dir}}/vars/lastpass-secrets.json"
    echo "" > "{{driver_dir}}/vars/lastpass-secretnotes.json"

    for LASTPASS_STEM in ${LASTPASS_STEMS[@]}
    do
	STEM_LENGTH_PLUS_ONE=$((${{"{#LASTPASS_STEM}"}} + 1))
	# the [4:] is because "stg_" is 4 characters:
	lpass show -j -x --basic-regexp "^$LASTPASS_STEM\_" | jq  ".[] | if (.username|length)>0 then {(.name[$STEM_LENGTH_PLUS_ONE:]+\"_user\"): .username, (.name[$STEM_LENGTH_PLUS_ONE:]+\"_pass\"): .password} else {} end" | jq -s add >> "{{driver_dir}}/vars/lastpass-secrets.json"
	lpass show -j -x --basic-regexp "^$LASTPASS_STEM\_" | jq  ".[] | if (.username|length)==0 then {(.name[$STEM_LENGTH_PLUS_ONE:]): .note} else {} end" | jq -s add >> "{{driver_dir}}/vars/lastpass-secretnotes.json"
    done

    jq -s add "{{driver_dir}}/vars/lastpass-secrets.json" > "{{driver_dir}}/vars/secrets.json"
    rm "{{driver_dir}}/vars/lastpass-secrets.json"
    jq -s add "{{driver_dir}}/vars/lastpass-secretnotes.json" > "{{driver_dir}}/vars/secretnotes.json"
    rm "{{driver_dir}}/vars/lastpass-secretnotes.json"

    lpass logout -f
else
    log_output local1.warning "lastpass only creates a file when SHCONFIG_ENV_TYPE is 'stg' or 'prd'"
fi

popd > /dev/null
