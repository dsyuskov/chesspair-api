# Multi-stage Dockerfile for ChessPair API

# Builder stage
FROM node:20-alpine AS builder
WORKDIR /app

# Установить зависимости
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy source and build
COPY . .
RUN npm run build

# Runtime stage
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production

# Copy built files and node_modules from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./

# Установить curl для healthcheck
RUN apk add --no-cache curl

EXPOSE 3000

CMD ["node", "dist/main"]
