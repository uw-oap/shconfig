#!/bin/sh
export BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $BASE_DIR

cd ..
source ./python_venv.sh
for i in $(python bin/list_vars.py "$@")
do
    if ! grep -rl "\b$i\b" src/ >/dev/null
    then
	echo "Unused variable: $i"
    fi
done
