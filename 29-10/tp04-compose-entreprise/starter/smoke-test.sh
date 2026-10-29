#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

resolve=(--resolve api.localhost:80:127.0.0.1)
base=http://api.localhost

echo "ready"
curl -fsS "${resolve[@]}" "$base/ready"
echo

miss=$(curl -fsS -D - "${resolve[@]}" -o /dev/null "$base/products" | awk 'tolower($1)=="x-cache:" {print $2}' | tr -d '\r')
hit=$(curl -fsS -D - "${resolve[@]}" -o /dev/null "$base/products" | awk 'tolower($1)=="x-cache:" {print $2}' | tr -d '\r')
echo "cache ${miss} puis ${hit}"
test "$hit" = "HIT"

echo "commande"
curl -fsS "${resolve[@]}" -X POST "$base/orders" \
  -H 'content-type: application/json' \
  -d '{"productId":1,"quantity":1}'
echo

for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  st=$(docker compose exec -T db psql -U shop -d shop -tAc "SELECT status FROM orders WHERE product_id=1 ORDER BY id DESC LIMIT 1")
  st=$(printf '%s' "$st" | tr -d '[:space:]')
  echo "status ${st}"
  if [ "$st" = "confirmed" ]; then
    exit 0
  fi
  sleep 1
done
echo "la commande n'est pas passée confirmed"
exit 1
