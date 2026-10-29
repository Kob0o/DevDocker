# Étape 3

`compose.override.yml` est pris tout seul. Port 3000 sur l'API, 5432 sur Postgres, 8080 sur le dashboard Traefik, `LOG_LEVEL=debug`.

J'ai ajouté un commentaire dans `src/server.js`. Le conteneur a redémarré tout seul :

```text
Restarting 'src/server.js'
{"signal":"SIGTERM","msg":"arrêt demandé"}
{"port":3000,"msg":"shopapi démarré"}
```

Le commentaire a été enlevé après.

# Étape 4

`traefik:v3.1` ne lit pas le socket Docker de ce poste (Engine 29). Le log répète `Failed to retrieve information of the docker client`. Avec `traefik:v3.6`, `http://api.localhost/ready` répond.

En prod, deux API. Six `curl /health`, les access logs alternent `http://172.24.0.3:3000` et `http://172.24.0.4:3000`. Pas de port 3000, 5432 ni 8080. `read_only`, `CapDrop ALL`, 256 Mo, 0.5 CPU.

`docker compose up -d --scale api=3` ajoute `shop-api-3`. Le `up -d` suivant l'enlève : le fichier a `deploy.replicas: 2`, Compose revient à ce nombre.

Le mot de passe n'est pas dans le compose. `scripts/with-db-url.sh` lit le secret et exporte `DATABASE_URL` avant `node`. Le code de l'API n'est pas touché.

# Étape 5

`./smoke-test.sh` : `/ready` ok, `/products` MISS puis HIT, une commande, le worker la passe `confirmed`. `make migrate M=002-add-sku.sql` ajoute la colonne `sku`.
