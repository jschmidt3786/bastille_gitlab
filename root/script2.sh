#!/bin/sh

mkdir -p /usr/local/etc/nginx/tls
cd /usr/local/etc/nginx/tls/ || exit
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout gitlab.key -out gitlab.crt
