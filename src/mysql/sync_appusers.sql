/* Add to this file whatever other users are needed, e.g. for WordPress */
INSERT IGNORE INTO mysql.user
       (user, host)
       VALUES
       ('{{secrets_backup_db_user}}', 'localhost');
FLUSH PRIVILEGES;
       
SET PASSWORD FOR '{{secrets_backup_db_user}}'@'localhost' = PASSWORD('{{secrets_backup_db_pass}}');

FLUSH PRIVILEGES;
