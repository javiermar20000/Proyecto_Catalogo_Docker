# Arquitectura Lógica — Flujo de Petición `/items`

Este documento describe el **flujo de comunicación y componentes** involucrados en el proyecto *Catálogo Dockerizado (API + Postgres + Nginx)*.  
El diagrama adjunto representa la **secuencia lógica** de una petición HTTP entre los distintos contenedores y servicios desplegados mediante Docker Compose.

---

## Componentes Principales

### 1. **Usuario (Cliente Web / Navegador)**
- Es el actor externo que realiza peticiones HTTP al sistema.
- Todas las solicitudes se dirigen a `localhost:8080`, el único puerto expuesto al host.
- No tiene acceso directo a la API ni a la base de datos.

---

### 2. **Nginx (Reverse Proxy)**
- Imagen: `nginx:alpine`
- Puerto interno: `8080`
- Es el único servicio con puerto publicado al host (`8080:8080`).
- Su función es **recibir las peticiones del cliente** y redirigirlas a la API a través de la red interna `edge`.
- Implementa balanceo **round-robin** si existen múltiples réplicas de la API (`--scale api=2`).

#### Configuración destacada
- Archivo de configuración: `reverse-proxy/nginx.conf`
- Cabeceras de seguridad agregadas a todas las respuestas:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: no-referrer`
- Manejo básico de errores (`404`, `timeout`).
- Propaga el encabezado `X-Request-Id` a la API para trazabilidad y pruebas de balanceo.

---

### 3. **API (Node/Express)**
- Imagen: `catalogo-api:latest`
- Puerto interno: `3000`
- Usuario dentro del contenedor: `app` (no root)
- Endpoints disponibles:
  - `GET /health` → retorna `{status: "ok"}`
  - `GET /items` → consulta la tabla `items` en Postgres
  - `POST /items` → inserta un nuevo registro (opcional)
- Usa variables de entorno definidas en `.env` y gestionadas por Docker Compose:
  ```
  DB_HOST, DB_PORT, DB_USER, DB_NAME, DB_PASSWORD_FILE
  ```
- `DB_PASSWORD_FILE` apunta al secreto montado en `/run/secrets/db_password`.
- La API pertenece simultáneamente a dos redes:
  - `backend` → comunicación con Postgres
  - `edge` → comunicación con el proxy Nginx
- Incluye healthcheck interno (`GET /health`).

---

### 4. **Postgres (Base de Datos)**
- Imagen: `postgres:16-alpine`
- Puerto interno: `5432`
- Base de datos inicializada mediante el script `db/seed.sql`, que crea e inserta datos en la tabla `items`.
- Variables gestionadas vía `.env`:
  ```
  POSTGRES_USER, POSTGRES_DB, POSTGRES_PASSWORD_FILE
  ```
- Volumen persistente: `pgdata` → `/var/lib/postgresql/data`
- Healthcheck configurado con `pg_isready`.
- Secretos gestionados con `secrets/db_password.txt`.

---

## Flujo de Comunicación (GET /items)

El siguiente flujo describe el proceso que se visualiza en el diagrama secuencial:

1. **El usuario** envía una solicitud:
   ```
   GET /items
   Host: localhost:8080
   ```

2. **Nginx (proxy)** recibe la petición y la reenvía internamente:
   ```
   proxy_pass http://api:3000/items
   X-Request-Id: $request_id
   ```
   - El encabezado `X-Request-Id` se utiliza para rastrear peticiones entre múltiples réplicas.

3. **La API (Express)** recibe la solicitud y ejecuta la consulta SQL:
   ```sql
   SELECT id, name, price FROM items;
   ```

4. **Postgres** procesa la consulta y devuelve las filas como JSON al servicio de API.

5. **La API** responde a Nginx con:
   ```json
   {
     "hostname": "api-1",
     "requestId": "a1b2c3",
     "data": [
       {"id":1,"name":"Cafetera","price":39990},
       {"id":2,"name":"Auriculares","price":25990}
     ]
   }
   ```
   - El campo `hostname` permite comprobar si el balanceo round-robin está funcionando (las respuestas alternan entre instancias).

6. **Nginx** devuelve la respuesta final al cliente agregando las cabeceras de seguridad.

---

## Seguridad y Gestión de Credenciales

- **No se exponen secretos en el código fuente.**
- Contraseña de Postgres gestionada como `secret` de Compose:
  ```
  secrets:
    db_password:
      file: ./secrets/db_password.txt
  ```
- El contenedor de la API lee el secreto desde `/run/secrets/db_password`.
- No se ejecuta ningún proceso como root.
- Solo el contenedor Nginx expone puertos externos.

---

## Persistencia y Recuperación

- **Volumen persistente:** `pgdata` conserva los datos incluso después de `docker compose down`.
- **Backups:** `make backup` ejecuta internamente:
  ```bash
  docker compose exec db pg_dump -U $DB_USER -d $DB_NAME > backup.sql
  ```
- **Restauración:** se hace con `make restore`:
  ```bash
  docker compose exec -T db psql -U $DB_USER -d $DB_NAME < backup.sql
  ```

---

## Observaciones de Diseño

| Elemento | Justificación |
|-----------|----------------|
| **Multi-stage build** | Reduce el tamaño de la imagen final de la API y mejora la seguridad. |
| **Usuario no root** | Evita privilegios elevados dentro del contenedor. |
| **Redes aisladas** | Aísla la comunicación `backend` (API↔DB) de la `edge` (Proxy↔API). |
| **Healthchecks** | Garantizan orden de arranque y monitoreo de disponibilidad. |
| **Balanceo simple** | Permite escalar la API y comprobar alternancia mediante `hostname`. |
| **Cabeceras seguras** | Evitan ataques comunes como clickjacking o MIME sniffing. |
| **Secretos externos** | Evitan almacenar contraseñas en imágenes o repositorios. |

---

## Resumen del flujo

1. El cliente accede a `localhost:8080`.
2. Nginx recibe y reenvía internamente a la API (`:3000`).
3. La API se conecta a Postgres (`:5432`) usando credenciales seguras.
4. Postgres devuelve resultados al contenedor de la API.
5. Nginx responde al cliente con datos JSON y cabeceras de seguridad.

---

## Referencia visual

<img width="838" height="510" alt="imagen" src="https://github.com/user-attachments/assets/05599551-4c0c-48fc-8ade-a3d5f4fb9fde" />

---
<img width="1913" height="510" alt="imagen" src="https://github.com/user-attachments/assets/5a6f84fd-de72-43bc-8910-f08aff0bbe23" />






![Diagrama de arquitectura lógica — Flujo /items](./diagrama_logico.png)
