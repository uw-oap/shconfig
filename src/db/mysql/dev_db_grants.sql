INSERT IGNORE INTO mysql.user
       (user, host)
       VALUES
       ('{{secrets_USERNAME_user}}', '%'),
FLUSH PRIVILEGES;
SET PASSWORD FOR '{{secrets_USERNAME_user}}'@'%' = PASSWORD('{{secrets_USERNAME_pass}}');

GRANT ALL PRIVILEGES ON *.* TO '{{secrets_USERNAME_user}}'@'%';

FLUSH PRIVILEGES;
