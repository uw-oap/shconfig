#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting setup_wordpress.sh"

###################
# Build WordPress #
###################

# creating this so we can put the `wp` command in it:
install -CD -m 0775 -o {{driver_user}} -g {{driver_group}} -d "{{php_dir}}/php/wp/bin"

# Be able to run wp via bin/wp.sh
if ! [ -e "{{php_dir}}/php/wp/bin/wp" ]
then
    curl -o "{{php_dir}}/php/wp/bin/wp" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
fi

install -C -m 0700 wp/wp.sh "{{driver_bindir}}/wp.sh"

if [ "{{shconfig_env_type}}" != "prd" ]
then
    install -C -m 0700 wp/convert-prod-wp-to-staging.sh "{{driver_bindir}}/convert-prod-wp-to-staging.sh"
fi


# If it's not a symbolic link...
if ! [ -L "{{wordpress_dir}}" ]
then
    log_output local1.info "Synchronizing WordPress using branch {{wordpress_repo_branch}}..."
    install_git_repo "{{wordpress_repo_branch}}" "{{wordpress_repo}}" "{{wordpress_dir}}" "--exclude uploads/  --exclude env.php  --exclude php.sh --exclude php-wrapper --exclude *.log --exclude .circleci/ --exclude cache/" " --exclude=blc-log.txt --exclude cache/* --exclude=phast.*/*"
fi


# Link plugins:
if ! [ -e "{{wordpress_dir}}/cms/wp-content/plugins/ap-hiring-plan" ]
then
    ln -s "{{hiringplan_dir}}/ap-hiring-plan" "{{wordpress_dir}}/cms/wp-content/plugins/ap-hiring-plan"
fi

if ! [ -e "{{wordpress_dir}}/cms/wp-content/plugins/ap-job-board" ]
then
    ln -s "{{jobboard_dir}}/ap-job-board" "{{wordpress_dir}}/cms/wp-content/plugins/ap-job-board"
fi

if ! [ -e "{{wordpress_dir}}/cms/wp-content/plugins/rolling-due-dates" ]
then
    ln -s "{{rollingdates_dir}}/rolling-due-dates" "{{wordpress_dir}}/cms/wp-content/plugins/rolling-due-dates"
fi

if ! [ -e "{{wordpress_dir}}/cms/wp-content/plugins/pt-info" ]
then
    ln -s "{{ptinfo_dir}}/pt-info" "{{wordpress_dir}}/cms/wp-content/plugins/pt-info"
fi


##################################
# Ensure WordPress is configured #
##################################

log_output local1.debug "Installing WordPress configuration files..."

install -CD -m 0775 -o {{driver_user}} -g {{apache_group}} -d "{{wordpress_dir}}/{{wordpress_webroot}}/wp-content/uploads"

# needed for cron jobs:
install -C -m 0555 wp/php.sh "{{wordpress_dir}}/php.sh"

install -D -o {{driver_user}} -g {{apache_group}} -m 0440 wp/env.php "{{wordpress_dir}}/env.php"
