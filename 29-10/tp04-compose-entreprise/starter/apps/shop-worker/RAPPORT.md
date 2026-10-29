# Étape 3

`--no-cache-dir` est enlevé du `pip install`. Avec, pip n'écrit rien dans `/root/.cache/pip`.

```text
time docker build --secret id=pipconf,src=pip.conf -t worker:1.0 .
real 1.79
RUN pip install ... CACHED
```

Même Dockerfile, même `requirements.txt` : la couche est reprise, pip n'est pas relancé.

```text
docker builder prune -f
Total: 129.2MB
```

Le mount était dans la liste : `ocrqg665`, 3,678 Mo, `cached mount /root/.cache/pip ... id "/pip-arm64"`. Après, `docker buildx du --filter type=exec.cachemount` est vide. Le sujet dit que ce prune ne touche pas au cache mount. Là il l'a supprimé.

```text
echo "requests==2.32.3" >> requirements.txt
time docker build --secret id=pipconf,src=pip.conf -t worker:1.0 .
real 8.16
RUN pip install ... DONE 6.5s
Downloading redis, psycopg2-binary, prometheus-client, requests
```

`requirements.txt` est remis aux 3 lignes d'origine.

La couche, c'est le résultat du `RUN`. Elle est réutilisée tant que l'instruction et les fichiers d'avant ne changent pas. `requirements.txt` change, la couche saute, pip repart.

Le mount, c'est `/root/.cache/pip`, gardé à côté et remonté au `RUN`. Il ne rentre pas dans l'image. Pip reprend les wheels déjà là (`Using cached`) et ne télécharge que le paquet nouveau. Comme le prune avait supprimé le mount, le build avec `requests` a tout re-téléchargé.

Sans prune, le mount venant d'être rempli, ajout de `six==1.16.0` :

```text
real 2.32
Using cached redis, psycopg2-binary, prometheus-client
Downloading six
```

`six` est retiré ensuite.

```text
docker build --no-cache --secret id=pipconf,src=pip.conf -t worker:1.0 .
real 5.06
Downloading redis, psycopg2-binary, prometheus-client
```

`--no-cache` ignore les couches. Sur ce build, les wheels sont re-téléchargés aussi.

# Étape 4

Le port 5000 est pris par AirPlay. Le registre écoute sur 5050.

```text
docker buildx create --name shop --driver docker-container --use
ERROR: existing instance for "shop" but no append mode
```

```text
docker buildx inspect --bootstrap
Name: shop
Driver: docker-container
Status: running
Platforms: linux/arm64, linux/amd64, linux/amd64/v2, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```

Le builder tourne dans un conteneur, le push passe par `host.docker.internal:5050`. `imagetools` est lancé depuis le Mac, donc `localhost:5050`.

```text
docker buildx build --platform linux/amd64,linux/arm64 \
  --secret id=pipconf,src=pip.conf \
  -t host.docker.internal:5050/shop-worker:1.0 --push .
real 1.59
pip id=pip-amd64   CACHED
pip id=pip-arm64   CACHED
```

```text
docker buildx imagetools inspect localhost:5050/shop-worker:1.0

MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:676809379a8a1ba108b9d4572217b3acfc8596a4dfb2b6da67e7363002727396

linux/amd64   sha256:330106db5873fc05cfa78a9c7bf67dd21f2ca2763b5c0aff512fc1d4791a691b
linux/arm64   sha256:8bfd572708705c22c218bfd4f2dac64898be862ddeef769110c02a2da092acf9
+ 2 attestation-manifest
```

`--push` ou `-o type=oci` : avec deux plateformes le résultat est une liste de manifests. Le moteur local n'en range qu'un, une seule arch. Il faut un registre, ou un fichier OCI.

Le manifest list est cet index. Il ne contient pas les couches. Il pointe un manifest par plateforme, et ici deux manifests d'attestation. Au pull, le client prend le manifest de son arch.

`ARG TARGETARCH` est `arm64` ou `amd64` selon la plateforme que BuildKit construit. Le cache pip est `id=pip-${TARGETARCH}`, cible `/root/.cache/pip`. Dans le log, le `RUN` arm64 a `id=pip-arm64`, le `RUN` amd64 a `id=pip-amd64`. Les wheels ne se mélangent pas.

Sur une machine amd64, arm64 passe par QEMU : les instructions sont traduites, le build est plus lent. L'alternative est un nœud natif dans le même builder, `docker buildx create --append --platform linux/arm64 ssh://...`. Ce nœud ne construit que cette plateforme. Le Mac est arm64, c'est donc amd64 qui serait émulé. Les deux `RUN` de ce build étaient `CACHED`, ce temps-là n'est pas dans le log.
