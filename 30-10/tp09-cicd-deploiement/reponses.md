# Étape 1

Dépôt `shop` : API, worker, `compose.yml`, `compose.prod.yml`, `release-gate.sh`. Le gate refuse une image root, sans `HEALTHCHECK`, sans les labels OCI `version` / `revision` / `source`, ou avec une CVE HIGH/CRITICAL qui a un correctif (`trivy --ignore-unfixed --exit-code 1`).

# Étape 2

`.github/workflows/ci.yml` : hadolint, `docker compose config`, matrice api/worker, build `--target test` sans push sur une PR. Sur `main` : tag `sha-<sha>` (metadata-action, pas de `latest`), cache `type=gha`, plateformes amd64+arm64, secret de build `pipconf` pour le worker, provenance et sbom, trivy bloquant, `cosign sign` keyless (OIDC). Un tag `v*` ajoute les tags semver et le job prod avec `environment: production`, après `cosign verify`.

Pas de `gh` ici, et le login SSH de la machine est coupé. `./ci-local.sh` rejoue hadolint, la config, les tests, le build, le gate, le push sur `127.0.0.1:5500` et une signature à clé locale. Le multi-arch, le cache GHA et le keyless restent dans le workflow : en local il n'y a pas d'OIDC.

Premier passage du gate : l'API est refusée. OpenSSL de l'image Alpine (`libssl3` 3.5.6-r0, corrigé en 3.5.9-r0) et npm, qui reste dans `node:20-alpine` alors que le process n'en a pas besoin (`tar` CRITICAL, `minimatch`, `brace-expansion`, …). Le Dockerfile final fait `apk add` des deux libs pinnées et supprime npm. Le worker était déjà à 0.

`./ci-local.sh` vert sur `sha-e6fa62503fae9e1fc18c532fd3870015331ef182` (hadolint ok, test API 1/1, gate ok des deux images, push, verify). L'image réellement déployée est `sha-dae9c4decd37ee3c1cdba52058064a2f32a4bf36` (même gate, poussée, signature vérifiée). Digest `sha256:c285eb182c87196c6ff2e0ec0d1117fdfdc10c3588a2d7744a163a2cf44afc55`. Cosign 3 n'accepte plus `--tlog-upload=false` dès qu'une signing-config est là : en local la config est vide, sans Rekor, et le verify utilise `--insecure-ignore-tlog`.

# Étape 3

```
docker context create preprod --docker "host=ssh://localhost"
docker --context preprod ps
```

Le contexte est créé. Le `ps` échoue : `ssh: connect to host localhost port 22: Connection refused`. Le partage de session n'est pas activé, pas d'utilisateur `deploy`.

Côté serveur il faut : Docker installé, un utilisateur `deploy` dans le groupe `docker`, sa clé publique dans `authorized_keys`, et sur le disque (pas dans git) le `.env` (`REGISTRY`, `VERSION`) et `secrets/db_password.txt`. Le fichier est monté en secret Compose au démarrage. Le pipeline ne le met pas dans l'image. La clé SSH du job est un secret du forge (`PREPROD_SSH_KEY` / `PROD_SSH_KEY`), pas le mot de passe de la base.

# Étape 4

Mesure sur la stack déjà en route (compose du TP04 + overlay durci), 100 req/s sur `http://api.localhost/health`. Au repos, 8 s : 800/800, 0 échec.

Naïf : `docker compose up -d --no-deps --force-recreate api` (les deux réplicas en même temps, sans `--wait`). Le `up` revient en 2 s. Sur 45 s : **4500 requêtes, 621 échecs** (502, puis timeouts, puis 404 le temps que Traefik reprenne les nouveaux conteneurs).

Rolling (`deploy/rolling-update.sh`, `VERSION=sha-dae9c4decd37ee3c1cdba52058064a2f32a4bf36`) : scale 3, on attend que le nouveau soit healthy, `touch /tmp/drain` sur l'ancien, 8 s, `docker stop -t 15`, puis on redescend à 2. **30 s, 5000 requêtes, 0 échec.**

Sans le drain, un essai précédent (stop direct) a fait **74 échecs sur 10000** : Traefik continue d'envoyer sur le conteneur le temps de son healthcheck (5 s), les requêtes partent en 499.

| Brique | Rôle | Si on l'enlève |
|---|---|---|
| HEALTHCHECK image | Le process répond vraiment | `--wait` ne voit qu'un conteneur « démarré », Traefik peut router vers un process pas prêt |
| `--wait` | On n'arrête personne tant que le nouveau n'est pas healthy | On coupe un ancien alors que le nouveau refuse encore |
| `start_period` | Les premiers échecs de sonde ne comptent pas | Un démarrage un peu lent passe unhealthy et Compose tue le conteneur |
| SIGTERM | `server.close` puis `closeAllConnections`, sortie avant 10 s | Docker attend `stop_grace_period` puis SIGKILL, les requêtes en cours sont coupées |
| `stop -t 15` | Le délai donné au process pour finir | SIGKILL tout de suite |
| 2 réplicas | Il en reste toujours un qui répond | Un seul réplica : le recreate est une coupure |
| Traefik ne route que vers `/ready` = 200 | `/tmp/drain` répond 503, le réplica sort du pool avant le stop | Les requêtes partent encore sur celui qu'on arrête |
| retry (2 essais) | Un 502 isolé est renvoyé sur l'autre réplica | Ce 502 arrive au client |

# Étape 5

`VERSION=sha-avant ./deploy/rolling-update.sh` : **30 s, 4500 requêtes, 0 échec.**

`sha-avant` et `sha-dae9c4decd37ee3c1cdba52058064a2f32a4bf36` sont le même digest (`c285eb182c87`), déjà sur la machine : pas de pull, le temps c'est la recréation. `shopapi:1.4.2` est encore là (`ca3e6946da63`). Le tag ne bouge pas une fois poussé, la signature est sur le digest. Revenir au tag remet la même image, pas « la dernière qu'on a build ».

Ça ne défait pas le schéma. `db/migrations/002-add-sku.sql` ajoute une colonne : l'ancienne image l'ignore, le retour arrière passe. Un `DROP COLUMN price` (ou un rename) non : l'ancienne image fait encore `SELECT price` et casse, alors que le tag est pourtant revenu. Il faut une migration en deux temps (ajouter le nouveau, déployer, n'enlever l'ancien qu'au déploiement d'après) ou une restauration de la base. Le tag d'image ne suffit pas.
