# Exercice 8

```bash
docker compose up -d --build
```

http://localhost:8080/api/v1/dogs

```bash
curl -s -X POST http://localhost:8080/api/v1/dogs \
  -H 'Content-Type: application/json' \
  -d '{"name":"Tao","birthDate":"2018-06-01","breed":"Yorkshire Terrier","sterilized":true}'
```
