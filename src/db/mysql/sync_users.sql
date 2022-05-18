{% if mysql_domains %}
  {% for domain_to_grant in mysql_domains %}
/* TODO: DELETE FROM mysql.user where domain_to_grant */
INSERT IGNORE INTO mysql.user
       (user, host)
       VALUES
       ('{{secrets_FIXME_user}}', '{{domain_to_grant}}');
FLUSH PRIVILEGES;

SET PASSWORD FOR '{{secrets_FIXME_user}}'@'{{domain_to_grant}}' = PASSWORD('{{secrets_FIXME_pass}}');
  {% endfor %}
{% endif %}

FLUSH PRIVILEGES;

INSERT IGNORE INTO mysql.user
       (user, host)
       VALUES
       ('{{secrets_FIXME_user}}', 'localhost');

FLUSH PRIVILEGES;

SET PASSWORD FOR '{{secrets_FIXME_user}}'@'localhost' = PASSWORD('{{secrets_FIXME_pass}}');

FLUSH PRIVILEGES;
