{% if rt_purge_attachment_queues %}
DELETE a FROM Attachments a
JOIN Transactions tr ON a.TransactionId = tr.id
JOIN Tickets t ON tr.ObjectId = t.id
JOIN Queues q ON t.Queue = q.id
WHERE (
 {% set or_str = joiner(" OR ") %}
 {% for q in rt_purge_attachment_queues %}
  {{ or_str() }}
  q.Name="{{q}}"
  {% endfor %}
)
AND (a.Filename IS NOT NULL)
   AND (a.Created < (CURDATE() - INTERVAL 90 DAY));
{% endif %}
