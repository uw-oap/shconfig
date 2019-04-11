<?php
define('DB_NAME', '{{wordpress_db_name}}');

/** MySQL database username */
define('DB_USER', '{{secrets_wp_db_user}}');

/** MySQL database password */
define('DB_PASSWORD', '{{secrets_wp_db_pass}}');

/** MySQL hostname */
define('DB_HOST', '{{wordpress_db_host}}');

define('WP_HOME', 'https://{{wordpress_webdomain}}');

define('WP_SITEURL', 'https://{{wordpress_webdomain}}');

if( strcmp("{{shconfig_env_type}}", "stg") == 0) {
    define('WP_DEBUG', true);
    define('SAVEQUERIES', true);
    define('WP_DEBUG_LOG', true);
    define('WP_DEBUG_DISPLAY', false);
} elseif( strcmp("{{shconfig_env_type}}", "prd") == 0) {
    define('WP_DEBUG', false);
    define('SAVEQUERIES', false);
    define('WP_DEBUG_LOG', false);
    define('WP_DEBUG_DISPLAY', false);
} elseif( strcmp("{{shconfig_env_type}}", "dev") == 0) {
    define('WP_DEBUG', true);
    define('SAVEQUERIES', true);
    define('WP_DEBUG_LOG', true);
    define('WP_DEBUG_DISPLAY', true);
}
?>
