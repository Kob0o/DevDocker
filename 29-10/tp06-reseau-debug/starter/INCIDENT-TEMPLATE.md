# Rapport d'incident — préprod Shop SAS

**Heure de début** : 9h51 · **Heure de résolution** : 9h55 · **Impact** : préprod indisponible, `localhost:8081` ne répond pas

## Rappels réseau

Deux conteneurs sur le bridge par défaut : `ping` répond `bad address`. `/etc/resolv.conf` pointe sur `192.168.65.7`, pas de DNS Docker. Sur un réseau créé avec `docker network create`, le résolveur est `127.0.0.11` et le ping par nom passe. `-p` publie un port sur l'hôte. `expose` n'ouvre rien. `internal` coupe l'accès vers l'extérieur. `network_mode: host` sort le conteneur des réseaux Compose, le nom DNS n'existe plus.

## Chronologie du diagnostic

| Heure | Symptôme observé | Commande / preuve | Hypothèse | Résultat |
|-------|------------------|-------------------|-----------|----------|
| 9:51 | `compose up` refuse de démarrer | `services.deploy.replicas: can't set container_name` | `container_name: api` et `replicas: 2` ensemble | confirmé |
| 9:52 | le fichier ne peut pas aller plus loin, je le lis | `compose.yml`, `default.conf` | plusieurs autres erreurs derrière | confirmé, liste ci-dessous |

## Anomalies trouvées

| # | Fichier / service | Anomalie | Correction | Catégorie |
|---|-------------------|----------|------------|-----------|
| 1 | api | `container_name` et `deploy.replicas: 2` | un seul conteneur, pas de nom forcé | cycle de vie |
| 2 | api | `command: node server.js` | le Dockerfile lance `src/server.js` | config |
| 3 | api | `PORT=8080` | l'API écoute sur 3000, comme nginx | config |
| 4 | api | `DATABASE_URL` vers `databse` | le service s'appelle `db` | config |
| 5 | api / db | l'API est sur `public`, Postgres sur `backend` | l'API est sur les deux | réseau |
| 6 | public | `internal: true` sur le réseau du front | `internal` est mis sur `backend` | réseau |
| 7 | redis | `network_mode: host` | Redis sur `backend`, nom `redis` | réseau |
| 8 | redis | `--requirepass r3dis` alors que l'URL n'a pas de mot de passe | mot de passe retiré | config |
| 9 | db | `pg_isready -U postgres` | l'utilisateur est `shop` | cycle de vie |
| 10 | front | `./nginx` (un dossier) monté à la place du fichier `default.conf` | montage de `default.conf` | stockage |
| 11 | nginx | `proxy_pass http://localhost:3000` | `http://api:3000` | réseau |
| 12 | front, api, redis | pas de healthcheck | healthchecks, `depends_on` healthy | cycle de vie |

Le `build` et `init.sql` pointaient vers `tp04/.../solution/`, ce dossier n'existe pas ici. Les chemins vont vers `starter/`.

## Pourquoi ça n'a pas été détecté avant ?

Le compose a été modifié et la personne est partie. Rien ne lance `docker compose config` ni un appel HTTP après le démarrage. Sans healthcheck, un conteneur « Up » peut ne rien servir.

## Actions de prévention

1. `docker compose config` dans la CI : l'erreur `container_name` + `replicas` aurait bloqué le merge.
2. Un smoke test `curl /products` après `up --wait`, le même que le TP04.
3. Healthchecks sur tous les services. `--wait` ne rend la main que si tout est sain.
