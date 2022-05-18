# Backup DB runs on dbserver:
INSERT IGNORE INTO mysql.user
       (user, host)
       VALUES
       ('{{secrets_backup_db_user}}', 'localhost'),
       ('', 'localhost'),
       ('', '{{shconfig_webserver}}'),
       ('{{secrets_rt_db_user}}', '{{shconfig_webserver}}'),
       ('{{secrets_rt_db_user}}', 'localhost'),
       ('{{secrets_wp_db_user}}', '{{shconfig_wpserver}}');
FLUSH PRIVILEGES;
       
SET PASSWORD FOR '{{secrets_backup_db_user}}'@'localhost' = PASSWORD('{{secrets_backup_db_pass}}');
SET PASSWORD FOR '{{secrets_rt_db_user}}'@'{{shconfig_webserver}}' = PASSWORD('{{secrets_rt_db_pass}}');
SET PASSWORD FOR '{{secrets_rt_db_user}}'@'localhost' = PASSWORD('{{secrets_rt_db_pass}}');
SET PASSWORD FOR '{{secrets_wp_db_user}}'@'{{shconfig_wpserver}}' = PASSWORD('{{secrets_wp_db_pass}}');

FLUSH PRIVILEGES;
