#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/starter"
OUT="$ROOT/backups"
mkdir -p "$OUT"

checksum() {
  docker exec "$1" psql -U shop -d shop -tAc \
    "SELECT md5(string_agg(id::text || status, ',' ORDER BY id)) FROM orders;"
}

docker compose up -d --wait

before="$(docker compose exec -T db psql -U shop -d shop -tAc "SELECT md5(string_agg(id::text || status, ',' ORDER BY id)) FROM orders;")"
before="$(printf '%s' "$before" | tr -d '[:space:]')"
echo "checksum avant ${before}"

docker compose exec -T db pg_dumpall -U shop > "${OUT}/upgrade-dumpall.sql"
docker compose exec -T db pg_dump -U shop -Fc shop > "${OUT}/upgrade.dump"
echo "dumps écrits"

docker compose stop db

echo "essai postgres 16 sur le volume 14"
set +e
err="$(docker run --rm \
  -e POSTGRES_PASSWORD=shop \
  -v shopdata_pgdata:/var/lib/postgresql/data \
  postgres:16.4-alpine 2>&1)"
code=$?
set -e
printf '%s\n' "$err" | tail -20
echo "exit ${code}"

docker volume create shopdata_pgdata16 >/dev/null
docker rm -f shopdata-pg16 >/dev/null 2>&1 || true
docker run -d --name shopdata-pg16 \
  --network shopdata_default \
  -e POSTGRES_USER=shop \
  -e POSTGRES_PASSWORD=shop \
  -e POSTGRES_DB=shop \
  -p 5433:5432 \
  -v shopdata_pgdata16:/var/lib/postgresql/data \
  postgres:16.4-alpine >/dev/null

for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if docker exec shopdata-pg16 pg_isready -U shop -d shop >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker exec -i shopdata-pg16 pg_restore -U shop -d shop --no-owner < "${OUT}/upgrade.dump"

after="$(checksum shopdata-pg16)"
after="$(printf '%s' "$after" | tr -d '[:space:]')"
echo "checksum après ${after}"

if [ "$before" = "$after" ]; then
  echo "verdict OK"
else
  echo "verdict KO"
  exit 1
fi
