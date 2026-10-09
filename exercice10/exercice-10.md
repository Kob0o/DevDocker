# Exercice 10

```bash
docker compose up -d --build
docker compose ps
```

```bash
curl -s http://localhost:8080/api/info/env
```

```bash
curl -s -X POST http://localhost:8080/api/notes \
  -H 'Content-Type: application/json' \
  -d '{"title":"Test persistance","content":"Cette note doit rester","category":"WORK","priority":"HIGH"}'

curl -s http://localhost:8080/api/notes
```
