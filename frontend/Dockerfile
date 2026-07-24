ARG NODE_VERSION=22

# ==================== build stage ====================
FROM node:${NODE_VERSION}-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

# ==================== production stage ====================
FROM nginx:1.27-alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY certs /etc/nginx/ssl

EXPOSE 8080
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
