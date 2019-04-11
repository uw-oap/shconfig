#!/bin/bash
set -e
. ../shared_functions.sh
. ./shared_functions2.sh
assert_driver

log_output local1.debug "Starting setup_wordpress.sh"

###################
# Build WordPress #
###################

log_output local1.debug "Making sure phpbrew for WP is installed"
if ! [ -e "{{php_dir}}/php/wp-{{wordpress_php_version}}/bin/php" ]
then
    phpbrew_fn install --name="wp-{{wordpress_php_version}}" {{wordpress_php_version}} "{{wordpress_php_variant}}" -- {{driver_php_buildoptions}}
fi

# Be able to run wp via bin/wp.sh
if ! [ -e "{{php_dir}}/php/wp-{{wordpress_php_version}}/bin/wp" ]
then
    curl -o "{{php_dir}}/php/wp-{{wordpress_php_version}}/bin/wp" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
fi

install -C -m 0700 wp/wp.sh "{{driver_bindir}}/wp.sh"

if [ "{{shconfig_env_type}}" != "prd" ]
then
    install -C -m 0700 wp/convert-prod-wp-to-staging.sh "{{driver_bindir}}/convert-prod-wp-to-staging.sh"
fi


# If it's not a symbolic link...
if ! [ -L "{{wordpress_dir}}" ]
then
    log_output local1.info "Synchronizing WordPress..."
    install_git_repo "{{wordpress_repo_branch}}" "{{wordpress_repo}}" "{{wordpress_dir}}" "--exclude uploads/  --exclude env.php  --exclude php.sh --exclude php-wrapper --exclude *.json --exclude *.log"
fi

##################################
# Ensure WordPress is configured #
##################################

log_output local1.debug "Installing WordPress configuration files..."

install -C -m 0555 wp/php-wrapper "{{wordpress_dir}}/php-wrapper"
install -C -m 0555 wp/php.sh "{{wordpress_dir}}/php.sh"
install -C -m 0444 wp/php.ini "{{php_dir}}/php/wp-{{wordpress_php_version}}/etc/php.ini"

install -CD -m 0775 -o {{driver_user}} -g {{apache_group}} -d "{{wordpress_dir}}/{{wordpress_webroot}}/wp-content/uploads"
# For all the files under uploads, make sure that user and group have read and write access
# -print0 uses NUL as the delimiter; xargs -0 means use NUL as the delimiter on the other end of the pipe
# (This protects against files with spaces in their names)
# xargs's -r skips running chmod if there are no files
find "{{wordpress_dir}}/{{wordpress_webroot}}/wp-content/uploads" -type f -user {{driver_user}} -print0 | xargs -r0 chmod ug+rw

install -CD -o {{driver_user}} -g {{apache_group}} -m 0440 wp/formidable-htaccess "{{wordpress_dir}}/{{wordpress_webroot}}/wp-content/uploads/formidable/form-data/.htaccess"
install -D -o {{driver_user}} -g {{apache_group}} -m 0440 wp/env.php "{{wordpress_dir}}/env.php"
