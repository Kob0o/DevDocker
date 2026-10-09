# Exercice 9

```bash
docker compose up -d --build
```

```bash
curl -s -X POST http://localhost:8080/api/v1/dogs \
  -H 'Content-Type: application/json' \
  -d '{"name":"Nala","birthDate":"2020-02-14","breed":"Labrador","sterilized":false}'

curl -s http://localhost:8081/api/v1/logs
```
