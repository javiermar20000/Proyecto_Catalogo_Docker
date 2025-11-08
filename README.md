# Catálogo — API + Postgres + Nginx (Docker + Compose)

Stack de referencia que empaqueta una API Node.js, PostgreSQL y un proxy Nginx usando Docker Compose. Sirve como base para practicar multi-stage builds, healthchecks encadenados, redes aisladas, manejo de secretos, escalamiento horizontal del servicio de aplicación y flujos de backup/restore persistentes.

- Integrante: Javier Alonso Martínez Sepúlveda

## Objetivos del stack de muestra
- Multi-stage build para la API (builder + runner no root) y reducción de superficie de ataque.
- Healthchecks reales (`pg_isready` y `GET /health`) que encadenan el arranque con `depends_on: condition: service_healthy`.
- Redes aisladas para separar tráfico interno (`backend`) y frontera expuesta (`edge`).
- Secretos de base de datos montados como archivo (`POSTGRES_PASSWORD_FILE` / `DB_PASSWORD_FILE`).
- Escalamiento del servicio API con balanceo round-robin vía Nginx.
- Persistencia de datos y estrategia de backup/restore utilizable desde `make`.

## Componentes
- **db** (`postgres:16-alpine`): base de datos con `pgdata` persistente y `db/seed.sql` para datos iniciales.
- **api** (imagen construida localmente): Node.js + Express, gestiona `/items` e inyecta `X-Request-Id` para trazabilidad.
- **proxy** (`nginx:1.27-alpine`): único punto expuesto (`8080`), añade cabeceras de seguridad y distribuye tráfico hacia la API.

## Estructura del proyecto
- `api/`: código de la API, Dockerfile multi-stage y dependencias.
- `db/seed.sql`: definición inicial de tabla `items` y dataset de ejemplo.
- `reverse-proxy/nginx.conf`: reverse proxy + headers de seguridad.
- `secrets/db_password.txt`: archivo montado como secreto en DB y API.
- `Makefile`: atajos para construir, levantar, escalar y operar servicios.
- `docker-compose.yml`: orquestación de servicios, redes, healthchecks y volúmenes.
- `backup.sql`: archivo generado por `make backup` (no versionado por defecto).
- `docs/`: documentación por componente (ver sección "Documentación detallada").

## Flujo de redes y seguridad
1. Clientes sólo alcanzan `proxy` en `localhost:8080` (puerto publicado en `edge`).
2. El proxy reenvía tráfico HTTP hacia `api` a través de la red `edge`; desde ahí la API habla con Postgres mediante la red `backend`.
3. La API corre como usuario `app` (no root) y nunca publica puertos hacia el host; usa `expose` para que Compose haga el linking.
4. Nginx refuerza cabeceras `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` y `Referrer-Policy: no-referrer` para mitigar ataques comunes.
5. Las credenciales de la base se resuelven leyendo `/run/secrets/db_password`, evitando variables de entorno en texto plano.

## Base de datos y persistencia
- `pgdata` guarda el estado en disco del contenedor `db`, por lo que reinicios o recreaciones conservan el contenido mientras el volumen exista.
- `db/seed.sql` se monta como `docker-entrypoint-initdb.d/` para crear la tabla `items` y cargar productos iniciales al primer arranque.
- El contenedor expone healthcheck `pg_isready -U $DB_USER -d $DB_NAME` con 10 reintentos cada 5s; sólo cuando responde "accepting connections" la API continúa.

## Healthchecks y arranque ordenado
- **DB**: `pg_isready` con `retries: 10`, `interval: 5s`, `timeout: 3s`.
- **API**: `wget -qO- http://localhost:${API_PORT}/health | grep -q 'ok'`.
- `depends_on: condition: service_healthy` en `api` y `proxy` garantiza el arranque en cadena (DB → API → Proxy) y reinicios automáticos si fallan.

## Makefile y automatización
| Objetivo | Descripción |
| --- | --- |
| `make up` | Construye (si es necesario) y levanta los servicios en segundo plano. |
| `make scale` | Escala la API a 2 réplicas manteniendo el resto igual. |
| `make down` | Detiene y elimina contenedores, redes efímeras y enlaces. |
| `make logs` | Sigue logs combinados de todos los servicios. |
| `make ps` | Muestra el estado de los contenedores del proyecto. |
| `make build` | Fuerza reconstrucción sin caché de las imágenes. |
| `make backup` / `make restore` | Dumpea/restaura la base desde `backup.sql`. |
| `make size` | Lista el tamaño de la imagen `catalogo-api`. |

## Puesta en marcha rápida
1. Copia `.env.example` → `.env` y ajusta variables (`DB_*`, `API_PORT`, etc.).
2. Define la contraseña en `secrets/db_password.txt` (texto no vacío).
3. Ejecuta `make up` para levantar `db`, `api` y `proxy`.
4. Verifica que `make ps` muestre los tres servicios `running` y que `curl localhost:8080/health` responda `{"status":"ok"}`.
5. Usa `make down` para detener todo, o continúa con las pruebas guiadas de la siguiente sección.

## Documentación detallada
Cada componente y práctica del stack se describe con mayor profundidad en `docs/`:
- `docs/api.md`
- `docs/database.md`
- `docs/proxy.md`
- `docs/networks.md`
- `docs/security.md`
- `docs/automation.md`
- `docs/healthchecks.md`
- `docs/scaling.md`
- `docs/backups.md`

## Guía de pruebas manuales (comandos + propósito)
Las siguientes pruebas cubren arranque, observabilidad, inserciones, escalamiento, persistencia y copias de seguridad. Ejecuta cada comando en la raíz del proyecto; posteriormente puedes añadir capturas de pantalla de los resultados.

### 1. `make up`
- **Propósito**: construir imágenes y levantar el stack inicial.
- **Resultado esperado**: contenedores `catalogo-db`, `catalogo-api`, `catalogo-proxy` en estado `running` con recreaciones sólo si cambió código.
- **Validación**: confirma que Compose crea las redes `backend` y `edge`, monta el secreto y respeta el orden DB → API → Proxy.
<img width="1105" height="408" alt="imagen" src="https://github.com/user-attachments/assets/a4736fe7-cabc-44e0-b2d9-38123a03090f" />


### 2. `make ps`
- **Propósito**: listar el estado y puertos expuestos.
- **Resultado esperado**: `proxy` con puerto `0.0.0.0:8080->8080/tcp`, `api` y `db` sin puertos host visibles.
- **Validación**: verifica que sólo el proxy sea accesible externamente y que los healthchecks estén `healthy`.
<img width="1187" height="166" alt="imagen" src="https://github.com/user-attachments/assets/e427b214-ac0f-4854-9422-74d5385c8ea7" />


### 3. `make logs`
- **Propósito**: inspeccionar logs en vivo (útil tras despliegue).
- **Resultado esperado**: mensajes de `API listening on 3000`, `database system is ready to accept connections`, solicitudes HTTP cuando hagas peticiones.
- **Validación**: asegura que no existan errores de conexión ni reinicios en bucle.
<img width="847" height="513" alt="imagen" src="https://github.com/user-attachments/assets/78997f3e-f037-414e-9eb2-5db108f46415" />


### 4. ``curl -s localhost:8080/health | jq``
- **Propósito**: comprobar el health endpoint expuesto vía Nginx.
- **Resultado esperado**: JSON con `{ "status": "ok", "hostname": "catalogo-api-1" }` (hostname depende del contenedor).
- **Validación**: demuestra que el proxy reenvía correctamente y mantiene cabeceras configuradas.
<img width="1185" height="143" alt="imagen" src="https://github.com/user-attachments/assets/9cb6bede-86a1-4caa-9a56-8cb529c8324e" />


### 5. ``curl -s localhost:8080/items | jq``
- **Propósito**: leer los items iniciales sembrados por `db/seed.sql`.
- **Resultado esperado**: arreglo `data` con tres productos (`Cafetera`, `Auriculares`, `Teclado`) y metadatos `hostname`/`requestId`.
- **Validación**: confirma conectividad API ↔ DB y serialización JSON.
<img width="1016" height="518" alt="imagen" src="https://github.com/user-attachments/assets/3036fa23-2227-4c93-8ffb-9891b653d3e4" />


### 6. ``curl -s -X POST localhost:8080/items -H 'Content-Type: application/json' -d '{"name":"Mouse","price":12990}' | jq``
- **Propósito**: insertar un nuevo producto para probar escrituras.
- **Resultado esperado**: respuesta `201` con `id` asignado y el objeto recién creado.
- **Validación**: verifica permisos de escritura, parsing de JSON y persistencia en Postgres.
<img width="1183" height="199" alt="imagen" src="https://github.com/user-attachments/assets/74faf784-0874-496e-bf3a-eccbf51a61c6" />


### 7. `make scale`
- **Propósito**: aumentar la API a dos réplicas manteniendo un único proxy.
- **Resultado esperado**: `catalogo-api-1` y `catalogo-api-2` corriendo, ambos unidos a `backend` y `edge`.
- **Validación**: prueba la capacidad de Compose para escalar horizontalmente servicios sin downtime.
<img width="1190" height="253" alt="imagen" src="https://github.com/user-attachments/assets/7efee81b-33d0-4756-a63d-19d51ca5d097" />


### 8. ``for i in {1..6}; do curl -s -H "X-Request-Id: test-$$i" localhost:8080/items | jq '.hostname'; done``
- **Propósito**: observar balanceo round-robin desde Nginx hacia las réplicas API.
- **Resultado esperado**: la salida alterna entre los hostnames de cada contenedor (`catalogo-api-1`, `catalogo-api-2`).
- **Validación**: demuestra que el proxy distribuye tráfico y que `X-Request-Id` se propaga para trazabilidad.
<img width="1190" height="239" alt="imagen" src="https://github.com/user-attachments/assets/2f549524-82e8-46e7-96ef-c68aad5195ae" />


### 9. ``curl -s -X POST localhost:8080/items -H 'Content-Type: application/json' -d '{"name":"SSD","price":59990}'``
- **Propósito**: insertar otro producto mientras hay múltiples réplicas.
- **Resultado esperado**: registro `SSD` persistido independientemente de la réplica que atienda.
- **Validación**: confirma consistencia de la base cuando la API escala.
<img width="391" height="27" alt="imagen" src="https://github.com/user-attachments/assets/10564a98-4da0-43ec-8d15-575a35a8cfe2" />


### 10. ``make down && make up``
- **Propósito**: simular un reinicio total del stack.
- **Resultado esperado**: al volver a subir, la base conserva las inserciones (gracias al volumen `pgdata`).
- **Validación**: comprueba la persistencia en disco más allá del ciclo de vida de los contenedores.
<img width="1137" height="507" alt="imagen" src="https://github.com/user-attachments/assets/2ae8b19b-881f-4bc3-9a1f-bf22d2e2ee89" />


### 11. ``curl -s localhost:8080/items | jq``
- **Propósito**: verificar que los productos `Mouse` y `SSD` siguen presentes tras el reinicio.
- **Resultado esperado**: lista con los cinco ítems (3 seed + 2 insertados) en orden por `id`.
- **Validación**: asegura integridad de datos y estado de la API luego del restart.
<img width="1500" height="1075" alt="imagen" src="https://github.com/user-attachments/assets/44a4ad9c-2cf0-49c4-86dd-84a1debf2f78" />


### 12. `make backup`
- **Propósito**: generar `backup.sql` usando `pg_dump` dentro del contenedor `db`.
- **Resultado esperado**: archivo en la raíz con comandos SQL mostrando las inserciones actuales.
- **Validación**: demuestra que los secretos/variables permiten operar utilidades administrativas de Postgres.
<img width="1168" height="114" alt="imagen" src="https://github.com/user-attachments/assets/5ac1a5de-ea85-408b-bb8b-ef08c3e07bb3" />

### 13. `make restore`
- **Propósito**: restaurar el backup recientemente generado.
- **Resultado esperado**: `psql` lee `backup.sql` sin errores; tras completarse, la data coincide con el dump.
- **Validación**: prueba la estrategia de recuperación ante desastres y permisos dentro del contenedor.


### 14. `make build`
- **Propósito**: reconstruir la imagen de la API usando el Dockerfile multi-stage.
- **Resultado esperado**: paso "Builder" instala dependencias y "Runner" copia sólo artefactos necesarios, finalizando con usuario `app`.
- **Validación**: asegura que los cambios en código o dependencias se empaqueten correctamente y que la idea de multi-stage se mantenga.
<img width="1449" height="1078" alt="imagen" src="https://github.com/user-attachments/assets/51d2affb-c548-44c6-a8ba-cc277753d522" />


### 15. `make size`
- **Propósito**: consultar el peso de la imagen final `catalogo-api`.
- **Resultado esperado**: línea con `REPOSITORY TAG SIZE`, evidenciando el beneficio de la etapa runner minimalista.
- **Validación**: sirve como métrica rápida para detectar incrementos inesperados de tamaño.
<img width="1176" height="124" alt="imagen" src="https://github.com/user-attachments/assets/b5c1b287-f814-49f1-b996-0674576305ef" />


---

