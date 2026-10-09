# Exercice 4

```bash
docker compose up -d --build
docker compose exec conteneur-a ping -c 3 conteneur-b
docker compose exec conteneur-b ping -c 3 conteneur-a
```
