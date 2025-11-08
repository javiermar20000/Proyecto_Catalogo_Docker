# Reverse Proxy (Nginx)

## Función
- Es el único servicio que publica puertos hacia el host (`8080:8080`).
- Sirve `/health`, `/items` y cualquier otra ruta hacia la API utilizando upstream `api_upstream` dentro de la red `edge`.

## Configuración (`reverse-proxy/nginx.conf`)
- `worker_processes auto` y `worker_connections 1024` para soportar múltiples conexiones concurrentes durante las pruebas.
- `upstream api_upstream { server api:3000; }`: Compose resuelve el hostname `api` gracias a la red compartida.
- `proxy_set_header X-Request-Id $request_id`: propaga identificadores que la API reutiliza para logging.
- Timeouts: `proxy_connect_timeout 3s` y `proxy_read_timeout 10s` para cortar conexiones colgadas.

## Cabeceras de seguridad añadidas
- `X-Content-Type-Options: nosniff` → evita sniffing de MIME.
- `X-Frame-Options: DENY` → bloquea clickjacking.
- `Referrer-Policy: no-referrer` → reduce filtración de URLs.

## Healthcheck indirecto
- El proxy depende del healthcheck de la API (`condition: service_healthy`), garantizando que sólo escucha cuando el backend ya respondió exitosamente.

## Uso en pruebas
- Todos los `curl` se dirigen a `localhost:8080`, demostrando que ni la API ni la DB exponen puertos directamente hacia el host.
