.PHONY: up prod-up migrate test tools

up:
	docker compose up -d --wait

prod-up:
	docker compose -f compose.yml -f compose.prod.yml up -d --wait

migrate:
	docker compose --profile ops run --rm -e MIGRATION=$(M) migrate

test:
	./smoke-test.sh

tools:
	docker compose --profile tools up -d --wait adminer
