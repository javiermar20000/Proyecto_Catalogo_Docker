# Automatización con Makefile

El `Makefile` simplifica la interacción con Docker Compose y operaciones de mantenimiento.

| Objetivo | Acción detallada |
| --- | --- |
| `make up` | Ejecuta `docker compose up -d`. Reconstruye imágenes según necesidad y levanta contenedores en background. |
| `make scale` | Corre `docker compose up -d --scale api=2`, manteniendo declarativos los contenedores existentes. |
| `make down` | Invoca `docker compose down` para detener servicios y eliminar redes efímeras. |
| `make logs` | Sigue (`-f`) los logs de todos los servicios con historial de las últimas 200 líneas. |
| `make ps` | Wrapper de `docker compose ps` para inspeccionar estado/resumen.
| `make build` | Reconstruye imágenes sin caché (`--no-cache`) ideal tras actualizar dependencias. |
| `make backup` | Ejecuta `pg_dump` dentro del contenedor `db` y redirige la salida al host (genera `backup.sql`). |
| `make restore` | Usa `psql` (stdin) dentro del contenedor para restaurar `backup.sql`. |
| `make sh-api` / `make sh-db` | Accesos interactivos a cada contenedor para depurar. |
| `make size` | Filtra `docker image ls` por `$(PROJECT)-api` para conocer el tamaño del artefacto final. |

Recomendación: exporta `PROJECT=catalogo` (o tu prefijo preferido) antes de usar `make size` para evitar coincidencias con otros proyectos.
