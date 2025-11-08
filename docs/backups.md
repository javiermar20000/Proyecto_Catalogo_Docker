# Backup y Restore

## Objetivo
Garantizar que el catálogo pueda recuperarse rápidamente ante errores humanos o fallos del servicio usando utilidades nativas de PostgreSQL dentro de los contenedores.

## Flujo de backup (`make backup`)
1. `docker compose exec db` abre una shell dentro del contenedor de Postgres.
2. Ejecuta `pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"`.
3. El resultado se redirige al host creando/actualizando `backup.sql` en la raíz del proyecto.

### Qué incluye el dump
- Esquema (`CREATE TABLE ...`).
- Datos actuales (`COPY ... FROM stdin`).
- Comandos para restaurar secuencias.

## Flujo de restore (`make restore`)
1. Usa `docker compose exec -T db` para ejecutar `psql` leyendo desde stdin.
2. Alimenta `backup.sql`, recreando tabla y datos.

## Buenas prácticas
- Versiona `backup.sql` sólo si deseas un dataset fijo; de lo contrario añádelo al `.gitignore`.
- Antes de restaurar en un entorno productivo, toma un backup adicional.
- Automatiza la ejecución periódica del objetivo `make backup` mediante cron o pipelines CI.

## Verificación posterior
- Corre `curl -s localhost:8080/items | jq` para validar que los registros coinciden con el dump.
- Usa `docker compose logs db` para confirmar que no se produjeron errores durante la importación.
