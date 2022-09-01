#!/bin/sh

if [ ! -f /app/localhost.crt ]
then
  openssl req -x509 -newkey rsa:4096 -keyout /app/localhost.key -out /app/localhost.crt -sha256 -days 365 -subj '/CN=localhost' -nodes
  chmod 644 /app/localhost.*
fi
/app/testserver
