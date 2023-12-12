{% if mysql_domains %}
  {% for domain_to_grant in mysql_domains %}

CREATE USER IF NOT EXISTS '{{secrets_user1_user}}'@'{{domain_to_grant}}';
SET PASSWORD FOR '{{secrets_user1_user}}'@'{{domain_to_grant}}' = '{{secrets_user1_pass}}';

  {% endfor %}
{% endif %}

FLUSH PRIVILEGES;
