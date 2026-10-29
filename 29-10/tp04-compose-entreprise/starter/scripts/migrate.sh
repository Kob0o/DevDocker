#!/bin/sh
set -eu
test -n "${MIGRATION:-}"
export PGPASSWORD="$(tr -d '\n' < /run/secrets/db_password)"
exec psql -h db -U shop -d shop -v ON_ERROR_STOP=1 -f "/migrations/${MIGRATION}"
