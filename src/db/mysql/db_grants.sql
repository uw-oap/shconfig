-- noinspection SqlDialectInspectionForFile
-- noinspection SqlNoDataSourceInspectionForFile

/* Access for OAP end users */
{% if mysql_domains %}
  {% for domain_to_grant in mysql_domains %}
/* For domain {{domain_to_grant}}... */

GRANT SELECT, SHOW VIEW ON *.* TO '{{secrets_user1_user}}'@'{{domain_to_grant}}';

  {% endfor %}
{% endif %}

/* web server -- datapipe */


FLUSH PRIVILEGES;
