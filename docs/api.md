# API (Node.js + Express)

## Rol dentro del stack
La API actúa como capa de negocio que expone endpoints REST sobre `/health` y `/items`. Consume PostgreSQL usando `pg` y entrega respuestas JSON con metadatos (`hostname`, `requestId`) para depurar tráfico cuando la aplicación escala horizontalmente.

## Dockerfile multi-stage (`api/Dockerfile`)
1. **Builder** (`node:20-alpine`): instala dependencias con `npm ci --omit=dev` y copia el código fuente.
2. **Runner**: crea el usuario no-root `app`, copia sólo `node_modules`, `src/` y `package*.json`, expone el puerto `3000` y ejecuta `node src/index.js`.
3. **Beneficio**: el artefacto final excluye herramientas de compilación y corre con privilegios mínimos.

## Código relevante (`api/src`)
- `index.js`: Express + middleware que garantiza `X-Request-Id` (si el proxy no lo envía, se genera con `uuid`). Endpoints:
  - `GET /health`: responde `{ status: 'ok', hostname }`; es la base del healthcheck Compose.
  - `GET /items`: consulta `items` ordenados y agrega `hostname` y `requestId` a la respuesta.
  - `POST /items`: inserta un registro y retorna `201` con el objeto persistido.
- `db.js`: crea un `Pool` reutilizable tomando credenciales de `DB_*` o del archivo indicado en `DB_PASSWORD_FILE`.

## Variables soportadas
| Variable | Descripción |
| --- | --- |
| `PORT` / `API_PORT` | Puerto interno expuesto (por defecto `3000`). |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_NAME` | Puntero hacia Postgres (se definen en `.env`). |
| `DB_PASSWORD_FILE` | Ruta del archivo con la contraseña (por defecto `/run/secrets/db_password`). |
| `NODE_ENV` | Modo de ejecución; Compose lo pasa según `.env`.

## Seguridad y observabilidad
- Corre como usuario `app` (no root) y sin `sudo` disponible.
- No publica puertos al host; `docker-compose` la alcanza vía redes internas (`backend` y `edge`).
- Inserta `X-Request-Id` tanto en la request como en la response para rastrear flujos multi-réplica.
- Registra el `HOSTNAME` del contenedor en cada respuesta, lo que ayuda a verificar balanceo.
