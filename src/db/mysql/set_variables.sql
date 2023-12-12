{# FYI ending a tag with -%} means that whitespace is stripped out

The context().items() exists due to
https://stackoverflow.com/a/3463669 and compile_scripts.py being
changed to pass `context` as a variable.
-#}
CREATE DATABASE IF NOT EXISTS shconfig;

use shconfig;

create table if not exists template_variables (
    k varchar(100) NOT NULL PRIMARY KEY,
    str_val varchar(255),
    json_val text
);

INSERT INTO template_variables (k, str_val, json_val)
  VALUES
{% for key, val in context() | dictsort -%}
{% if not callable(val) and not key.startswith('secret') and not key.startswith('_') and not key.startswith('driver') -%}
   ('{{ key }}', '{{val|escape|truncate(250)}}', '{{val|tojson|truncate(250)}}'){% if not loop.last %},{% endif %}
{% endif -%}
{% endfor %}
  ON DUPLICATE KEY UPDATE str_val=VALUES(str_val), json_val=VALUES(json_val);
