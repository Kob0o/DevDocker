#!/usr/bin/env bash
# Dump logique + copie brute du volume. Garde les 7 derniers de chaque.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="${COMPOSE_DIR:-$ROOT/starter}"
OUT="${BACKUP_DIR:-$ROOT/backups}"
mkdir -p "$OUT"

stamp="$(date +%Y%m%d-%H%M%S)"
cd "$COMPOSE_DIR"

project="$(docker compose config --format json | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')"
vol="${project}_pgdata"

echo "dump logique ${stamp}"
docker compose exec -T db pg_dump -U shop -Fc shop > "${OUT}/shop-${stamp}.dump"

echo "copie brute ${vol}"
docker run --rm \
  -v "${vol}:/data:ro" \
  -v "${OUT}:/backup" \
  alpine:3.20 \
  tar czf "/backup/pgdata-${stamp}.tgz" -C /data .

keep() {
  ls -1t $1 2>/dev/null | awk 'NR>7' | while IFS= read -r old; do
    rm -f "$old"
  done
}
keep "${OUT}/shop-*.dump"
keep "${OUT}/pgdata-*.tgz"

echo "ok ${OUT}/shop-${stamp}.dump"
echo "ok ${OUT}/pgdata-${stamp}.tgz"
