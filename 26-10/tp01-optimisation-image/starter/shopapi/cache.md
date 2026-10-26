# Étape 2 — invalidation du cache

## Pourquoi `npm install` est rejoué

Dans le Dockerfile historique :

```dockerfile
COPY . /app
RUN npm install
```

Docker ne réutilise une instruction que si elle est identique et que la couche d'avant l'est aussi. Le commentaire change `src/server.js`. Ce fichier part dans le `COPY .`, donc cette couche change, et `npm install` qui est juste derrière est invalidé avec elle.

`npm install` ne se sert que de `package.json`. Le commentaire ne change aucune dépendance. Il est rejoué à cause de sa place dans le fichier, pas parce que les paquets ont changé. En CI, c'est l'install complet (~4 min dans l'énoncé). Ici les paquets étaient déjà en local, d'où les 5 s, mais l'étape a bien été refaite.

## Ordre des couches idéal

Copier le manifeste, installer, et seulement ensuite copier le code. Le code change souvent, `package.json` non.

```text
        dernière couche (le code, souvent invalidé)
        +----------------------------------+
        | CMD ["node", "src/server.js"]    |
        +----------------------------------+
        | COPY src/   (+ test/ s'il faut)  |
        +----------------------------------+
        | RUN npm install                  |
        +----------------------------------+
        | COPY package.json                |
        +----------------------------------+
        | WORKDIR /app                     |
        +----------------------------------+
        | image de base                    |
        +----------------------------------+
        première couche
```

Avec cet ordre, le même commentaire ne refait que le `COPY` des sources. `npm install` reste en cache tant que `package.json` ne bouge pas.
