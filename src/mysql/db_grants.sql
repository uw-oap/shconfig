/* Put your database grants here. Usually the pattern is to iterate over the entries in secrets.json */

GRANT SELECT, RELOAD, SHOW DATABASES, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER ON *.* TO '{{secrets_backup_db_user}}'@'localhost';

FLUSH PRIVILEGES;
