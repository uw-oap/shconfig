#!/bin/sh
export BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $BASE_DIR

cd ..
source ./python_venv.sh
python bin/compare_vars.py "$@"
