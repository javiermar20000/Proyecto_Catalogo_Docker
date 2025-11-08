# Redes y comunicación

## Redes definidas en `docker-compose.yml`
| Red | Participantes | Propósito |
| --- | --- | --- |
| `backend` | `api`, `db` | Segmento privado para tráfico de base de datos. Ningún puerto se publica en el host. |
| `edge` | `proxy`, `api` | Capa expuesta donde el proxy habla con la API y publica el puerto `8080` hacia el exterior. |

## Flujo de peticiones
1. Cliente → `proxy` (`edge`).
2. `proxy` → `api` (sigue en `edge`).
3. `api` → `db` (`backend`).

La separación evita que la base de datos quede accesible desde el host o redes externas; sólo la API puede alcanzarla.

## Beneficios
- Facilita la aplicación de reglas de firewall/container-level (si se extendiera el proyecto hacia Swarm/Kubernetes).
- Permite monitorear y depurar tráfico por segmento.
- Habilita balanceo entre réplicas de la API sin tocar la red de la DB.
