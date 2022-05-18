-- noinspection SqlDialectInspectionForFile

-- noinspection SqlNoDataSourceInspectionForFile

/* Access for end users */
{% if mysql_domains %}
  {% for domain_to_grant in mysql_domains %}
/* For domain {{domain_to_grant}}... */

FIXME

  {% endfor %}
{% endif %}

/* backups */
GRANT SELECT, RELOAD, SHOW DATABASES, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER ON *.* TO '{{secrets_backup_db_user}}'@'localhost';

FLUSH PRIVILEGES;
