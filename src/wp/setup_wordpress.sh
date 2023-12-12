#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting setup_wordpress.sh"

###################
# Build WordPress #
###################

# If it's not a symbolic link...
if ! [ -L "{{wordpress_dir}}" ]
then
    log_output local1.info "Synchronizing WordPress using branch {{wordpress_repo_branch}}..."
    install_git_repo "{{wordpress_repo_branch}}" "{{wordpress_repo}}" "{{wordpress_dir}}" "--exclude uploads/"
fi


##################################
# Ensure WordPress is configured #
##################################

log_output local1.debug "Installing WordPress configuration files..."

# for WordPress logs
install_apache -CD -m 0770 -d "{{wordpress_dir}}/var"
