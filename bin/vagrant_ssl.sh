set -e

openssl genrsa -out /etc/ssl/private/ca.key 2048
openssl req -new -x509 -days 36500 \
  -subj "/FIXME" \
  -nodes -key /etc/ssl/private/ca.key -out /etc/ssl/certs/ca.crt

openssl genrsa -out /etc/ssl/private/localhost.key 2048
openssl rsa -in /etc/ssl/private/localhost.key -traditional > /etc/ssl/certs/wp-rsa.key
openssl req -new -key /etc/ssl/private/localhost.key \
  -subj "/FIXME" \
  -out /etc/ssl/certs/localhost-req.csr
openssl x509 -req -in /etc/ssl/certs/localhost-req.csr -days 36500 \
  -CAcreateserial -CA /etc/ssl/certs/ca.crt -CAkey /etc/ssl/private/ca.key \
  -out /etc/ssl/certs/localhost.crt
chown www-data /etc/ssl/private/localhost.key
chmod a+x /etc/ssl/private
