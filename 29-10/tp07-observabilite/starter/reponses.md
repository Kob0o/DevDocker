# Étape 1

`shop-api-1` logge du JSON sur stdout. Le driver est `json-file`, `max-size` 10m, `max-file` 3.

Sans `max-size`, le fichier du conteneur grossit pendant des mois et finit par remplir le disque.

L'appli écrit sur stdout. Docker récupère ce flux. Un fichier écrit dans le conteneur reste dans la couche writable : il part avec le conteneur, et `docker logs` ne le voit pas.

`json-file` : un fichier JSON par conteneur, `docker logs` le lit. `local` : le même rôle, format plus compact. `journald` : les logs vont dans le journal de la machine. `fluentd` et `awslogs` : les lignes partent vers un collecteur, il n'y a rien à relire en local.

`mode: non-blocking` : si le driver est lent, l'appli n'attend pas. Le tampon (`max-buffer-size`) jette les lignes en trop. En `blocking` (le défaut), l'appli ralentit mais on ne perd pas de ligne.

`docker run --log-driver none` : le conteneur affiche sa ligne pendant le `run`, puis `docker logs` répond `configured logging driver does not support reading`.

Le fichier json-file est dans la VM, `/var/lib/docker/containers/<id>/<id>-json.log`. Il n'est pas dans le dossier du Mac.

# Étape 2

`shop-api-1` était à environ 28 Mo / 256 Mo. `docker update --memory 64m` puis `./load.sh 150`. `docker inspect` : `OOMKilled=true`. La limite a été remise à 256 Mo après.

# Étape 3

Prometheus scrape l'API avec `dns_sd_configs` sur le nom `api` (port 3000) et le worker sur `worker:9100`. Le DNS Docker renvoie une IP par réplica.

`docker_sd_configs` a besoin du socket. L'image Prometheus tourne en `nobody`, le socket n'est pas lisible. Promtail, lui, est root, donc le socket lui sert à lire tous les logs. Les labels `service` et `project` viennent des labels Compose. Le champ `level` du JSON est extrait.

Grafana est sur le port 3001, `admin` / `admin`. Les datasources et le dashboard `Shop` sont des fichiers, pas des clics.

`docker exec` sur Prometheus : `uid=65534(nobody)`. Les 5 cibles sont `up` : les deux réplicas `api` (172.24.0.3 et 172.24.0.4, port 3000), `worker:9100`, `cadvisor:8080`, Prometheus lui-même.

`./load.sh 200`, puis `sum(rate(http_request_duration_seconds_count[1m])) by (status)` : seulement le status 200, environ 0,74 req/s juste après. Le dashboard Shop (port 3001, admin/admin) montre le pic et les logs.

Loki : `{service="api"} | json | level="50"` ne renvoie rien, pas d'erreur pino pendant la charge. Un POST `/orders` avec `quantity` 500 donne chez le worker `commande ... -> rejected`, et `{service="worker"} |= "rejected"` retrouve la ligne.

`ApiDown` est passé `firing` en mettant `shop-api-1` en pause (~30 s, cible 172.24.0.3:3000 en `up=0`). Le conteneur a été relancé, les deux API sont de nouveau `up`. `ContainerRestarting` et `MemoryNearLimit` restent inactives : cAdvisor répond, mais sur Docker Desktop les séries n'ont pas le label `name` du conteneur.

Captures : `captures/grafana-shop-dashboard.png`, `captures/prometheus-alerts-firing.png`.
