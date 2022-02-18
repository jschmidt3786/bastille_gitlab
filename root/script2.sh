#!/bin/sh

mkdir -p /usr/local/etc/nginx/tls
cd /usr/local/etc/nginx/tls/ || exit
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout gitlab.key -out gitlab.crt

printf "attempt adding a Let's Encrypt signed keypair? (anything but 'y' cancels) " >&2
read -r option
if [ "$option" = "y" ]; then
  pkg install -y security/py-certbot security/py-certbot-nginx
  printf "FQDN to register? " >&2
  read -r FQDN
  certbot --nginx -d "$FQDN"
  sysrc -f /etc/periodic.conf weekly_certbot_enable="YES"
else
  echo maybe some other time...
fi
