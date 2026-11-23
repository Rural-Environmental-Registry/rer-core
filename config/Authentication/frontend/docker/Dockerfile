# ============================
# 1) Dependencies Stage
# ============================
FROM node:18-alpine AS dependencies

# Atualizar pacotes para corrigir CVEs
RUN apk update && apk upgrade --no-cache

WORKDIR /app

# Instalar pnpm globalmente
RUN npm install -g pnpm@9

# Copiar apenas arquivos de dependências primeiro
COPY package.json pnpm-lock.yaml ./

# Instalar dependências com cache otimizado
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --prefer-offline

# ============================
# 2) Build Stage
# ============================
FROM dependencies AS build
COPY . .
ENV CI=true
ENV NODE_ENV=production
RUN pnpm run build

# ============================
# 3) Runtime Stage
# ============================
FROM nginx:alpine AS final

# Atualizar pacotes para corrigir CVEs
RUN apk update && apk upgrade --no-cache

# Copiar arquivos buildados
COPY --from=build /app/dist /usr/share/nginx/html${BASE_URL}${AUTHENTICATION_FRONTEND_KEYCLOAK_BASE_URL}

# Configurar nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Criar diretórios de cache e ajustar permissões
RUN mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp && \
    chown -R nginx:nginx /var/cache/nginx && \
    chmod -R 755 /var/cache/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

EXPOSE 8080
USER nginx
