# Étape 4 — conformité

Commandes de l'énoncé, image `shopapi:1.4.2`.

```text
docker image ls shopapi:1.4.2
shopapi:1.4.2   disk 212MB   content 51.7MB

docker run --rm shopapi:1.4.2 id
uid=1000(node) gid=1000(node) groups=1000(node),1000(node)

docker run --rm shopapi:1.4.2 ls /app
node_modules
package.json
src
```

Pas de `.env`, pas de `.sql`.

```text
docker inspect shopapi:1.4.2 --format '{{json .Config.Labels}}' | jq
version   1.4.2
revision  905a2b2
source    https://github.com/Kob0o/DevDocker
title     shopapi
```

```text
sleep 6 && docker inspect api --format '{{.State.Health.Status}}'
healthy

curl -s localhost:3000/products | jq
3 produits (clavier, écran, souris)

time docker stop api
real 0.14
exit 0
```

`node:20-alpine` seul est déjà à 194 Mo de disk usage. Avec les `node_modules` de prod on est à 212 Mo sur le disque. La taille de contenu (ce qui part au registry) est 52 Mo, sous les 200 Mo. Le dépassement des 212 Mo, c'est npm, yarn et corepack livrés dans l'image officielle.

## Arrêt : legacy vs nouvelle image

Nouvelle image, `docker stop` : **0,14 s**, code de sortie **0**.

Legacy, `docker stop` sans option : **1,21 s**, code **137**. `docker inspect` montrait `StopTimeout=1` sur le conteneur, donc la grâce n'était pas de 10 s sur cette machine. Avec `docker stop -t 10` (le délai dont parle l'énoncé) : **10,19 s**, code **137**.

137 = 128 + 9, c'est un SIGKILL. Le process n'est pas sorti tout seul.

Le Dockerfile d'origine a `CMD npm start`, forme shell. PID 1 c'est `/bin/sh -c "npm start"`. Docker envoie SIGTERM à ce shell, qui ne le passe pas à `node`. Le handler dans `server.js` ne tourne pas. Au bout du délai, Docker envoie SIGKILL.

Le nouveau `CMD` est `["node", "src/server.js"]`. `node` est PID 1, il reçoit SIGTERM, ferme le serveur et sort. `docker stop` revient tout de suite.

# Étape 5 — avant / après

|                                                   | legacy                                        | 1.4.2                                                        |
| ------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| Taille (`docker image ls`)                        | 1,06 Go disque, 279 Mo de contenu             | 212 Mo disque, 52 Mo de contenu                              |
| Nombre de couches (`docker history`)              | 18                                            | 21                                                           |
| Rebuild après un commentaire dans `src/server.js` | 6,46 s, `npm install` rejoué                  | 0,53 s, `npm install` resté `CACHED`, seul `COPY src` refait |
| Utilisateur                                       | `uid=0(root)`                                 | `uid=1000(node)`                                             |
| `docker stop`                                     | 10,19 s puis SIGKILL (exit 137, avec `-t 10`) | 0,14 s, exit 0                                               |

On a plus de couches qu'avant parce que `node:20-alpine` en empile déjà une dizaine. Elles sont petites à côté des 379 Mo d'apt et des 173 Mo de NodeSource du legacy.

Dockerfile final : `Dockerfile` dans ce dossier.

```text
hadolint Dockerfile
(aucune sortie, exit 0)
```

`USER` est `1000` et pas le nom `node` : avec le nom, hadolint laisse une info DL3066 et la sortie n'est plus vide. C'est le même compte, `id` affiche `uid=1000(node)`.
