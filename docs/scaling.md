# Escalamiento y balanceo

## Escalar la API
- Comando principal: `make scale` (equivalente a `docker compose up -d --scale api=2`).
- Puedes ajustar el número de réplicas cambiando `--scale api=N` manualmente.

## Qué sucede internamente
1. Compose crea contenedores `catalogo-api-1`, `catalogo-api-2`, etc.
2. Todos se conectan a las redes `backend` y `edge` y comparten el secreto de DB.
3. Nginx utiliza `upstream api_upstream` con estrategia round-robin por defecto, enviando peticiones de forma alternada.

## Cómo validar
- Ejecuta varias veces `curl -s localhost:8080/items | jq '.hostname'` o usa el bucle incluido en la guía (`for i in {1..6} ...`).
- Observa que la respuesta alterna entre hostnames distintos, demostrando que las réplicas atienden peticiones.

## Cuándo volver a una sola réplica
- Corre `docker compose up -d --scale api=1` o simplemente `make up` (que respeta el último estado del archivo Compose).

## Escenarios de uso
- Pruebas de resiliencia antes de un deploy.
- Simulación de horizontal scaling sin necesidad de un orquestador completo.
- A/B testing ligero si se introduce lógica condicional por hostname.
