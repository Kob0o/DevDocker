#!/bin/sh
# Charge l'API du TP04 via Traefik. Usage : ./load.sh 1000
n=${1:-200}
i=0
while [ "$i" -lt "$n" ]; do
  curl -s -o /dev/null --resolve api.localhost:80:127.0.0.1 "http://api.localhost/products?n=$i" &
  i=$((i + 1))
  if [ $((i % 50)) -eq 0 ]; then
    wait
  fi
done
wait
echo "ok $n"
