# Diagnostic shopapi

J'ai build l'image avec le Dockerfile d'origine, sans y toucher :

```bash
docker build -t shopapi:legacy .
```

Ensuite j'ai enchaîné `docker image ls`, `docker history`, `id`, `ls /app`, plus hadolint et dive. Dix problèmes, rangés comme demandé.

## Taille / performance

### 1. L'image fait plus d'1 Go

```text
docker image ls shopapi:legacy
shopapi:legacy   1.06GB (disk)   279MB (content)
```

`docker history` additionné tourne autour de 780 Mo de couches. On part d'Ubuntu 22.04 (80 Mo) pour une API Node. On est au-dessus des 200 Mo du référentiel, et chaque pull traîne cette base.

### 2. Des outils de compilation sont installés pour rien

La couche `apt-get install -y curl wget vim git build-essential python3` pèse **379 Mo**. Dans le conteneur :

```text
docker run --rm shopapi:legacy bash -lc 'command -v vim; command -v git; command -v python3'
/usr/bin/vim
/usr/bin/git
/usr/bin/python3
```

wget, curl, vim et un compilateur C ne servent pas à lancer l'API. Ça gonfle l'image et ça laisse de quoi bricoler dedans une fois qu'on a un shell.

### 3. Les listes apt restent dans l'image

`apt-get update` est un `RUN` à part. Dans l'historique cette couche fait **80,7 Mo**. `du -sh /var/lib/apt/lists` dans le conteneur donne **77 Mo**.

Comme le `rm` des listes n'est pas dans le même `RUN` que l'`update`, supprimer les fichiers plus bas ne rend pas l'espace : la couche est déjà enregistrée. hadolint le signale (`DL3009`).

### 4. `npm install` embarque les dépendances de dev

`NODE_ENV=development` est posé après l'install, donc il ne filtre rien. L'historique donne :

```text
RUN npm install -g nodemon    7.54MB
RUN npm install              63.5MB
```

`/usr/bin/nodemon` est là, et `node_modules` contient `eslint` et `nodemon`. L'image de prod n'a pas besoin de ça. En plus le `npm install` est après `COPY .`, donc il est refait à chaque modif de code (voir `cache.md`).

### 5. Pas de `.dockerignore`, `COPY .` prend tout

```text
docker run --rm shopapi:legacy ls -la /app
.env
.gitignore
Dockerfile
dump-prod-2024.sql
node_modules
package.json
src
test
```

Le dump ne fait que 47 octets dans ce starter (c'est écrit « dump simulé »), mais un vrai dump de prod partirait dans l'image et dans le contexte envoyé au daemon à chaque build.

## Sécurité

### 6. Le conteneur tourne en root

```text
docker run --rm shopapi:legacy id
uid=0(root) gid=0(root) groups=0(root)
```

`docker inspect` a `User` vide. Une faille dans Express ou dans une dépendance, et c'est root dans le conteneur.

### 7. Le mot de passe Postgres est dans une couche

`docker history` montre :

```text
ENV DATABASE_URL=postgres://shop:S3cret!@db.…
```

La variable est aussi dans l'environnement du process (`env` contient `DATABASE_URL`). Elle reste lisible dans l'historique même si on la retire dans une instruction plus bas. Quelqu'un qui peut pull l'image a le login de la base.

### 8. Le `.env` d'un dev est dans `/app`

`ls` le montre (179 octets). Il a été copié avec `COPY .`. Dedans : `DATABASE_URL`, `REDIS_URL` et `AWS_SECRET_ACCESS_KEY`. Le serveur ne charge pas dotenv, le fichier est quand même dans l'image qu'on pousserait au registry.

## Exploitabilité

### 9. Le `CMD` est en forme shell, Node ne voit pas `SIGTERM`

```text
docker inspect shopapi:legacy --format '{{json .Config.Cmd}}'
["/bin/sh","-c","npm start"]
```

PID 1 c'est `/bin/sh`, pas `node`. Le `shutdown` de `server.js` ne s'exécute pas au `docker stop` : Docker attend 10 s puis envoie `SIGKILL`. hadolint `DL3025`, et le build affiche `JSONArgsRecommended`. C'est cohérent avec les rolling updates qui traînent.

### 10. Pas de `HEALTHCHECK`

```text
docker inspect shopapi:legacy --format '{{json .Config.Healthcheck}}'
null
```

Le conteneur est « running » dès que le process est là, même si le port 3000 n'écoute pas. L'orchestrateur peut envoyer du trafic trop tôt. Il n'y a pas non plus de labels `org.opencontainers.image.version` / `revision` / `source`, donc on ne sait pas quel commit tourne sans ouvrir l'image.

dive, pour situer : efficacité 99,6 %, environ 4 Mo de fichiers dupliqués (logs dpkg, cache debconf). Le poids vient des paquets installés, pas de couches qui se répètent. hadolint ajoute `DL3008` (apt sans version), `DL3016` (`nodemon` non épinglé) et `DL4006` (le `curl | bash` NodeSource, sans `pipefail`).
