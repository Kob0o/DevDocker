# Étape 1

`starter/docker-compose.yml` :

1. `version: '3'` ne sert plus. Compose l'ignore, et le fichier mélange ça avec des clés récentes.
2. `links` est l'ancien moyen de joindre les conteneurs. Tout tombe dans le réseau par défaut, la base est joignable comme l'API.
3. `postgres` et `redis` sans tag. Un `pull` un autre jour peut changer la version majeure.
4. `5432` et `6379` sont publiés. La base et Redis sont ouverts sur le poste, pas seulement pour l'API.
5. `POSTGRES_PASSWORD: postgres` et le même mot de passe dans `DATABASE_URL`. Le secret est dans le fichier versionné.
6. `sleep 10` avant `node`. Si Postgres met plus de 10 s, l'API démarre quand même. S'il est déjà prêt, on attend pour rien.
7. Aucun `healthcheck`. Rien ne dit si la base accepte les connexions.
8. Pas de volume nommé. Les données de Postgres vivent dans la couche du conteneur, elles partent avec lui.
9. `restart: always` seulement sur le worker. L'API, la base et Redis restent arrêtés après un reboot.
10. Pas de limite CPU ni mémoire. Un conteneur peut prendre toute la machine.
