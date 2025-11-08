PROJECT?=catalogo


.PHONY: up down logs ps build backup restore sh-api sh-db size


up:
	docker compose up -d


scale:
	docker compose up -d --scale api=2


down:
	docker compose down


logs:
	docker compose logs -f --tail=200


ps:
	docker compose ps


build:
	docker compose build --no-cache


backup:
# Genera backup.sql en el directorio actual
	docker compose exec db sh -lc 'pg_dump -U "$${POSTGRES_USER}" -d "$${POSTGRES_DB}"' > backup.sql


restore:
# Restaura desde backup.sql
	docker compose exec -T db sh -lc 'psql -U "$${POSTGRES_USER}" -d "$${POSTGRES_DB}"' < backup.sql


sh-api:
	docker compose exec api sh


sh-db:
	docker compose exec db sh -lc 'psql -U $$DB_USER -d $$DB_NAME'


size:
	docker image ls | grep $(PROJECT)-api || true
