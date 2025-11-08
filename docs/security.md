# Seguridad aplicada al stack

## Principios
- **Mínimo privilegio**: la API corre como usuario `app` (no root) y sólo recibe el puerto interno `3000`.
- **Exposición controlada**: únicamente `proxy` publica `8080`; `api` y `db` se mantienen aislados dentro de sus redes.
- **Seguridad por capas**: Nginx filtra y agrega cabeceras defensivas antes de llegar a la API.
- **Protección de secretos**: contraseñas almacenadas como archivos en `secrets/` y montadas mediante Docker Secrets.

## Elementos concretos
- Dockerfile multi-stage reduce dependencias e imagen final (menor superficie de ataque).
- Healthchecks evitan que servicios dependientes arranquen si la capa inferior no está lista, reduciendo estados intermedios inconsistentes.
- Cabeceras HTTP:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: no-referrer`
- `X-Request-Id` en la API permite correlacionar logs y detectar anomalías.

## Próximos pasos que se pueden considerar a futuro
- Integrar TLS terminando en Nginx.
- Añadir autenticación a la API (token/API key) y policies de CORS.
- Incorporar escaneo de vulnerabilidades durante `make build` (por ejemplo con `docker scout` o `trivy`).
