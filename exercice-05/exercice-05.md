# Exercice 5

```bash
docker compose up -d
```

Vérifier que les données restent :

```bash
docker compose rm -sf mysql
docker compose up -d
```

Vérifier le redémarrage :

```bash
docker compose exec mysql bash -c 'kill -9 1'
docker compose ps
```
