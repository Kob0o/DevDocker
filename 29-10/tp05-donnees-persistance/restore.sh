#!/usr/bin/env bash
# Restaure le dernier dump logique dans la base du compose courant.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="${COMPOSE_DIR:-$ROOT/starter}"
OUT="${BACKUP_DIR:-$ROOT/backups}"

dump="${1:-}"
if [ -z "$dump" ]; then
  dump="$(ls -1t "${OUT}"/shop-*.dump | head -1)"
fi
test -f "$dump"

cd "$COMPOSE_DIR"
docker compose up -d --wait

echo "restore ${dump}"
docker compose exec -T db pg_restore -U shop -d shop --no-owner --clean --if-exists < "$dump"
echo "restauré"
