# Healthchecks y arranque ordenado

## Base de datos (`db`)
- **Comando**: `pg_isready -U $DB_USER -d $DB_NAME`.
- **Intervalo**: 5 segundos. **Timeout**: 3 segundos. **Reintentos**: 10.
- **Efecto**: Compose marca el contenedor como `healthy` únicamente cuando Postgres acepta conexiones.

## API (`api`)
- **Comando**: `wget -qO- http://localhost:${API_PORT}/health | grep -q 'ok'`.
- **Dependencia**: espera a que la base esté `healthy` antes de ejecutarse (via `depends_on`).
- **Respuesta esperada**: `{ "status": "ok", "hostname": "..." }`.

## Proxy (`proxy`)
- **Configuración**: `depends_on` apunta a `api` con `condition: service_healthy`.
- **Resultado**: el proxy sólo abre el puerto `8080` cuando la API ya pasó su healthcheck.

## Beneficios
1. Reinicios ordenados tras fallas: si Postgres se cae, Compose reinicia y la API espera hasta que vuelva a estar disponible.
2. Deploys deterministas: se evita que la API falle al arrancar por "connection refused".
3. Observabilidad: `docker compose ps` marca `healthy` en cada servicio, facilitando inspecciones rápidas.
