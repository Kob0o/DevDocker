# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS test
WORKDIR /app
COPY requirements.txt requirements-dev.txt ./
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true \
    pip install --no-cache-dir -r requirements-dev.txt
COPY worker ./worker
COPY tests ./tests
RUN python -m pytest

FROM python:3.12-slim AS runtime
WORKDIR /app
COPY --from=builder /install /usr/local
COPY worker ./worker
CMD ["python", "-m", "worker.main"]
