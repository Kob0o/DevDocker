#!/bin/sh
# L'appli ne lit que DATABASE_URL. Le mot de passe reste dans le secret.
set -eu
if [ -f /run/secrets/db_password ]; then
  pw=$(tr -d '\n' < /run/secrets/db_password)
  export DATABASE_URL="postgres://shop:${pw}@db:5432/shop"
fi
exec "$@"
