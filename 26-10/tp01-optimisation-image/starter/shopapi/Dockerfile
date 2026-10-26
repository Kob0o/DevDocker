FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

FROM node:20-alpine AS test
WORKDIR /app
COPY package.json ./
RUN npm install
COPY src ./src
COPY test ./test
RUN npm test && npm run lint

FROM node:20-alpine
ARG APP_VERSION=dev
ARG GIT_SHA=local

LABEL org.opencontainers.image.title="shopapi" \
      org.opencontainers.image.description="API catalogue produits Shop SAS" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="https://github.com/Kob0o/DevDocker"

ENV NODE_ENV=production \
    APP_VERSION=${APP_VERSION}

WORKDIR /app
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src

# 1000 = user node de node:20-alpine. hadolint râle sur le nom (DL3066).
USER 1000
EXPOSE 3000

HEALTHCHECK --interval=5s --timeout=3s --start-period=3s --retries=3 \
    CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

CMD ["node", "src/server.js"]
