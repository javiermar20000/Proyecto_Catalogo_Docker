# ===== Builder =====
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src


# ===== Runner minimal (no-root) =====
FROM node:20-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app
# Crear usuario no-root
RUN addgroup -S app && adduser -S -G app app


# Copiar solo artefactos necesarios
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package*.json ./


# Drop privileges
USER app
EXPOSE 3000
CMD ["node", "src/index.js"]