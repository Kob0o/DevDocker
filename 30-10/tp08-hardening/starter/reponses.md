# Étape 1

`./audit.sh shop` regarde les conteneurs du projet `shop`. Un écart, c'est : process root, privileged, `CapDrop` sans `ALL`, rootfs en écriture, pas de limite mémoire, pas de `PidsLimit`, pas de `no-new-privileges`, socket Docker montée. Sortie dans `audit-avant.txt`. **24 écarts**, code retour 1.

| Conteneur | Écarts |
|---|---|
| shop-api-1, shop-api-2 | pids |
| shop-worker-1 | user root, pids |
| shop-db-1 | cap-drop, rootfs, pids, no-new-privileges |
| shop-redis-1 | cap-drop, rootfs, pids, no-new-privileges |
| shop-traefik-1 | user root, cap-drop, rootfs, pids, no-new-privileges, socket |
| shop-db-backup-1 | user root, cap-drop, rootfs, mémoire, pids, no-new-privileges |

L'API tourne déjà en uid 1000, rootfs read-only, `cap_drop ALL`, mémoire 256 Mio. Postgres est en uid 70 et Redis en 999, mais le user n'est pas fixé au `run` : `docker exec` part en root. Personne n'a de `PidsLimit`. Traefik monte `/var/run/docker.sock`. Le backup n'a pas de limite mémoire.

L'image Hub `docker/docker-bench-security:latest` date de 2019 (client Docker 18.06). Le moteur 29 refuse ce client. Monter `/etc` en lecture seule empêche aussi le conteneur de démarrer (`/etc/hostname` read-only). Le script **1.6.0** du dépôt a été lancé avec le client local. 117 checks, **score -3**. Les checks d'hôte (section 1, fichiers `/etc/docker`, auditd) ne voient pas la VM de Docker Desktop.

Cinq WARN utiles pour la stack :

1. **5.32** la socket est dans `shop-traefik-1` (aussi cAdvisor et Promtail).
2. **4.1** pas d'utilisateur fixé : worker, traefik, backup, et le bench compte aussi db et redis.
3. **5.11** `shop-db-backup-1` n'a pas de limite mémoire. L'API, le worker, db, redis et traefik en ont une.
4. **5.29** aucun conteneur n'a de limite de PIDs.
5. **5.26** `no-new-privileges` manque sur db, redis, traefik et le backup (l'API et le worker l'ont déjà). Le démon ne le pose pas non plus (2.14).

# Étape 2

Image `alpine:3.20`, conteneurs jetés après chaque essai.

| Mesure | Ce qui s'est passé |
|---|---|
| `--read-only` | `touch /x` : `Read-only file system` (code 1). Avec `--tmpfs /tmp`, `touch /tmp/x` passe (code 0). |
| `--cap-drop ALL` | `chown 1:1 /tmp` : `Operation not permitted`. `--cap-add CHOWN` et le chown passe. `ping` marche quand même : `ping_group_range` vaut `0 2147483647`, l'ICMP non privilégié est ouvert. Avec `--sysctl net.ipv4.ping_group_range=1 0`, ping répond `permission denied` ; `--cap-add NET_RAW` le refait marcher. `apk add curl` passe sans cap en plus (fichiers à root). `apk add nginx` écrit `/run/nginx` pour l'utilisateur nginx : il faut **CHOWN** (chown), **FOWNER** et **DAC_OVERRIDE** (chmod ensuite). SETUID et SETGID ne changent rien. |
| `no-new-privileges` | `/bin/busybox` est `0755`, pas setuid. `passwd` est un lien vers busybox. Aucun binaire setuid dans l'image, donc `passwd` n'élève rien. Un petit programme en C, `chmod 4755`, lancé par `nobody` : sans le flag, `ruid=65534 euid=0`. Avec `--security-opt no-new-privileges`, `euid` reste 65534. |
| `--pids-limit 50` | La boucle de 100 `sleep` s'arrête sur `can't fork: Resource temporarily unavailable` (code 2). Le `ps \| wc -l` n'est pas atteint. |
| `--memory 32m` | Alpine n'a pas Python. `python:3.12-alpine`, `python -c "x='a'*100_000_000"`. Exit 137, `OOMKilled=true`. La swap était à 64 Mio (défaut, deux fois la limite) et ça n'a pas suffi. |
| `--user 1000` | `id` : `uid=1000 gid=0`. Un bind mount créé sur le Mac apparaît comme uid 1000 dans le conteneur (Docker Desktop réécrit le propriétaire), donc lecture et écriture passent. Un volume nommé avec un fichier root en `0600` : `cat` et `touch` en uid 1000 sont `Permission denied`. |
| seccomp | `unshare --user` : `Operation not permitted`. Le même avec `--security-opt seccomp=unconfined` affiche `ok`. Le profil par défaut (`moby/profiles`, `defaultAction` = `SCMP_ACT_ERRNO`) est une allowlist. Sur aarch64, libseccomp connaît 312 appels. Pour un conteneur avec les caps par défaut, **52** ne sont pas autorisés, dont `unshare`, `mount`, `keyctl`, `bpf`, `io_uring_*`. |
