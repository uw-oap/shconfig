DELETE a
FROM Attachments a
JOIN Transactions tr ON a.TransactionId = tr.id
JOIN Tickets origt ON tr.ObjectId = origt.id
JOIN Tickets t ON origt.EffectiveId = t.id
WHERE t.Status IN (
  'done',
  'resolved',
  'rejected',
  'cancelled')
   AND t.Resolved < NOW() - INTERVAL 1 year
   AND a.Filename IS NOT NULL;
