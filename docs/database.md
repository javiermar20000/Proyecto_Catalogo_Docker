# Base de Datos (PostgreSQL 16)

## Configuración
- Imagen base `postgres:16-alpine` con nombre de contenedor `catalogo-db` (o prefijo definido por `COMPOSE_PROJECT_NAME`).
- Variables definidas en `.env` (`DB_NAME`, `DB_USER`) y contraseña leída desde el secreto `/run/secrets/db_password` (`POSTGRES_PASSWORD_FILE`).
- Healthcheck `pg_isready -U $DB_USER -d $DB_NAME` con `retries: 10`, `interval: 5s`, `timeout: 3s`.

## Datos iniciales y esquema
- `db/seed.sql` crea la tabla `items(id SERIAL, name TEXT, price NUMERIC(12,2))` y carga 3 productos.
- El archivo se monta como `docker-entrypoint-initdb.d/seed.sql` en modo lectura, ejecutándose sólo cuando el volumen `pgdata` se crea por primera vez.

## Persistencia
- Volumen nombrado `pgdata` montado en `/var/lib/postgresql/data` para conservar datos entre `make down` / `make up`.
- Para reiniciar desde cero basta con eliminar el volumen (`docker volume rm catalogo_pgdata`) si se desea.

## Secretos
- La contraseña se aloja en `secrets/db_password.txt`, se mapea como Docker Secret `db_password` y se proyecta dentro del contenedor en `/run/secrets/db_password`.
- Evita exponer contraseñas en `docker inspect`, `env` o logs.

## Herramientas administrativas
- `make backup`: ejecuta `pg_dump` desde `docker compose exec db` y redirige la salida a `backup.sql` (en el host).
- `make restore`: aplica `backup.sql` usando `psql` dentro del contenedor.
- `make sh-db`: abre una shell de `psql` autenticada con las variables del servicio.
