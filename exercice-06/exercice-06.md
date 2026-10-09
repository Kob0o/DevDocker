# Exercice 6

```bash
docker run -d --name site-dev -p 8080:80 -v "$(pwd)/site:/usr/share/nginx/html" nginx
```

Modifier `site/index.html`, puis recharger la page.
