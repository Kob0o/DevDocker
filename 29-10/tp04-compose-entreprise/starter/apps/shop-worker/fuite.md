# Étape 1

Le build de l'énoncé plante : le registre interne n'existe pas, `worker:leak` n'est pas créé. Pip a quand même le temps d'écrire l'URL dans le log. J'ai mis `secret-marker` à la place du mot de passe du sujet, pour que le `grep -i secret` matche. `Tr3sS3cret` sortirait au même endroit.

```text
Looking in indexes: http://pypi.internal.example.com/simple/secret-marker
ERROR: No matching distribution found for redis==5.0.8
```

Sans image, `docker history` et `docker inspect` ne lisent rien. J'ai refait un build qui réussit : un `RUN` écrit l'ARG dans `/tmp/index-url`, le `RUN` d'après supprime le fichier.

```text
docker history --no-trunc worker:leak | grep -i secret

ARG PIP_INDEX_URL=http://pypi.internal.example.com/simple/secret-marker
RUN |1 PIP_INDEX_URL=http://.../secret-marker /bin/sh -c printf ... > /tmp/index-url
RUN |1 PIP_INDEX_URL=http://.../secret-marker /bin/sh -c rm -f /tmp/index-url
```

Le `|1`, c'est l'ARG encore collé à la commande. Il est aussi sur la ligne du `rm`. Le fichier est parti, l'historique garde l'URL. Quelqu'un qui pull l'image la lit avec `docker history`.

```text
docker inspect worker:leak --format '{{json .Config.Env}}'
```

Pas de `PIP_INDEX_URL` dedans. Un ARG ne devient pas une variable d'environnement tout seul. Si le Dockerfile faisait `ENV PIP_INDEX_URL=$PIP_INDEX_URL`, `inspect` l'afficherait, et tous les conteneurs lancés avec.

`cat /tmp/index-url` dans l'image finale échoue. En rebuildant seulement le stage d'avant le `rm` (`--target mid`), le `cat` renvoie encore l'URL. Supprimer le fichier dans un `RUN` plus bas ne touche pas la couche d'avant.

Le Dockerfile d'origine fait aussi `COPY . .` avant le `pip install`. `pip.conf.example` (l'URL avec le mot de passe) partirait dans cette couche, même si le `RUN` d'après plante.
