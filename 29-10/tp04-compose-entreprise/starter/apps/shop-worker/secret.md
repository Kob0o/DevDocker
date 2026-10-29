# Étape 2

`pip.conf` est à côté du Dockerfile, dans le `.gitignore`. Pour la formation il pointe vers `https://pypi.org/simple`.

```bash
docker build --secret id=pipconf,src=pip.conf -t worker:1.0 .
```

BuildKit le monte sur `/etc/pip.conf` le temps du `pip install`, puis l'enlève. Ce n'est pas un `COPY`.

```text
docker history worker:1.0 | grep -i -E 'secret|pip.conf|PIP_INDEX'
(rien)

docker run --rm worker:1.0 cat /etc/pip.conf
cat: /etc/pip.conf: No such file or directory
```

`import redis, psycopg2, prometheus_client` passe. pytest c'est l'autre stage : `docker build --target test`, 2 tests ok. `worker:1.0` c'est le stage `runtime`, sans pytest.

Le `RUN pip install` n'est même pas dans l'historique de `worker:1.0`. Il reste dans `builder`. On ne copie que `/install` vers `/usr/local`. Pas de `|1 PIP_INDEX_URL=...` comme avec l'ARG.

Pour un dépôt git privé, `--mount=type=ssh` et `docker build --ssh default` passent l'agent SSH le temps du `RUN` (`pip install git+ssh://git@github.com/org/prive.git`). La clé ne rentre pas dans l'image. Il faut l'avoir ajoutée avant avec `ssh-add`.

Pour un token, `--secret id=TOKEN,env=TOKEN` le met dans une variable, seulement pour ce `RUN`. Pas dans l'env de l'image, pas dans `history`. Ici `pip.conf` suffit : pip lit `/etc/pip.conf` tout seul.
