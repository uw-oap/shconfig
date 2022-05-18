# run this with `source`

export PHPBREW_ROOT=/data/phpbrew
export PHPBREW_HOME=/data/phpbrew

# 2020-07-07 jhb - this // is an intentional goof to keep phpbrew
# from removing phpbrew from the PATH
export PATH="/data/os/usr/bin://data/phpbrew/bin:$PATH"
export LD_LIBRARY_PATH="/data/os/usr/lib64"
source /data/phpbrew/bashrc
