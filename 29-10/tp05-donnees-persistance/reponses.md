# Étape 1

La stack du TP04 tourne. `shop_pgdata` est monté sur `/var/lib/postgresql/data`. Le point de montage vu par Docker est `/var/lib/docker/volumes/shop_pgdata/_data`, dans la VM, pas un dossier du Mac.

`docker exec db touch /tmp/x` puis `docker diff` : `A /tmp/x`. C'est la couche writable du conteneur. Un fichier posé dans `/var/lib/postgresql/data` n'apparaît pas dans `docker diff`. Il est dans le volume.

Copie du projet `shopcopy`, pour ne pas toucher `shop_pgdata` :

- `down` : le volume `shopcopy_pgdata` est encore là
- `down -v` : le volume est supprimé
- `stop` puis `rm -f` : le conteneur part, le volume reste
- `volume prune` sans option n'enlève pas un volume nommé. Il enlève un volume anonyme que plus aucun conteneur n'utilise. `docker rm` tout court laisse ce volume anonyme. `docker rm -v` le supprime avec le conteneur. C'est le piège : on croit avoir tout jeté, le volume anonyme reste et prend de la place, et on ne sait plus à quoi il servait.

Bind mount : le code, `init.sql`, un secret. Sur Docker Desktop le fichier passe par la VM, les petits fichiers sont lents. Volume nommé : les données Postgres et Redis, ça reste après un `down`. `tmpfs` : `/tmp` en prod, perdu à l'arrêt du conteneur, pas pour la base.

`init.sql` n'est lancé que si le répertoire de données est vide. Au premier boot : `running /docker-entrypoint-initdb.d/01-init.sql`. Après un `restart`, plus rien. Pour recommencer, `down -v` puis `up`. Ça efface les données.

# Étape 2

`seed.sh` : 100000 commandes, checksum `d0db8dd0c80411d21e86136be0ee6899`.

`backup.sh` écrit `shop-20261029-165022.dump` (`pg_dump -Fc`) et `pgdata-20261029-165022.tgz` (tar du volume). `down -v`, `up`, `restore.sh`. Le checksum après est le même : `100000|d0db8dd0c80411d21e86136be0ee6899`.

Le tar d'un Postgres en train d'écrire peut couper une page en deux. Il est cohérent si on arrête Postgres avant, ou si on encadre le tar avec `pg_backup_start` / `pg_backup_stop`. Le `pg_dump` est déjà cohérent.

Le sidecar `prodrigestivill/postgres-backup-local:16` (`SCHEDULE=@every 1m`) a écrit `/backups/last/shop-20261029-154951.sql.gz`. Le log dit `SQL backup created successfully`.

# Étape 3

Postgres 16 sur le volume du 14 :

```text
FATAL:  database files are incompatible with server
DETAIL:  The data directory was initialized by PostgreSQL version 14, which is not compatible with this version 16.4.
```

Les fichiers d'une version majeure ne sont pas ceux de la suivante. D'où un volume neuf.

`pg_dumpall` sort tout le cluster en SQL (rôles compris). `pg_dump -Fc` sort une base, restaurable avec `pg_restore`.

Checksum avant et après : `d0db8dd0c80411d21e86136be0ee6899`.

Retour arrière : le volume `shopdata_pgdata` n'a pas été modifié. J'ai arrêté le conteneur 16, relancé le compose en 14, le checksum était le même. Le 16 a été remis ensuite.

Le trou, c'est le temps du dump plus celui du restore. On le réduit avec de la réplication logique, ou `pg_upgrade --link` dans un conteneur qui a les deux binaires.

# Étape 4

`redis-server --save 60 1` : un snapshot si au moins une clé a changé en 60 s. Un crash peut perdre ces 60 s. `--appendonly yes` : le journal AOF, en `everysec` on perd environ une seconde.

Dans la stack, Redis a le cache `products` (TTL 30 s) et la file `orders:queue`. Le cache peut disparaître. La file, non : ce sont les commandes pas encore confirmées. L'AOF est le niveau qui colle. Le compose lance Redis avec `--appendonly yes`.
