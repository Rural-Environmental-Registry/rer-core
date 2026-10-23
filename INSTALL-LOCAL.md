# RER — Instalação Local (Docker/Podman Compose)

## Pré-requisitos
- Docker 24+ ou Podman 5+ com podman-compose
- 4GB RAM livre (13 containers)

## Quick Start

```bash
git clone https://github.com/Rural-Environmental-Registry/core.git
cd core
cp .env.example .env

# Build local das imagens (necessário na primeira vez)
# Requer os repos irmãos clonados em ../frontend, ../authentication, ../backend
podman build --build-arg VITE_BASE_URL=/ -t rer-core-frontend:local ../frontend
podman build --build-arg BASE_PATH=/auth --build-arg VITE_BASE_URL=/auth/ -t rer-auth-frontend:local ../authentication/frontend
podman build -t rer-auth-keycloak:local ../authentication
podman build -t rer-core-backend:local ../backend
podman build -t rer-auth-backend:local ../authentication/cardpg

# Subir tudo
docker compose up -d   # ou: podman compose up -d
# Aguardar ~50s (Keycloak demora)
```

## Acesso

| URL | O que é |
|-----|---------|
| http://localhost/ | Frontend principal (redireciona para login) |
| http://localhost/auth/login | Tela de login |
| http://localhost/keycloak/admin/ | Console admin Keycloak |
| http://localhost/geoserver/web/ | GeoServer UI |

## Credenciais

| Serviço | Usuário | Senha |
|---------|---------|-------|
| App (login) | admin-cardpg@gmail.com | Admin@123 (reset via Keycloak admin) |
| Keycloak admin | admin | admin |
| GeoServer | admin | geoserver |

## Fluxo de Autenticação

```
Browser → http://localhost/
  → core-frontend verifica token no localStorage
  → Não tem → redireciona para /auth/login (VITE_AUTH_MODULE_URL)
  → auth-frontend exibe formulário
  → Usuário digita email + senha
  → auth-frontend chama POST /keycloak/realms/car-dpg/protocol/openid-connect/token
  → Keycloak retorna JWT
  → auth-frontend chama GET /auth-backend/api/keycloak/credentials/{email}
  → auth-backend busca usuário por email no Keycloak admin API
  → Se OK → auth-frontend faz redirect para VITE_FRONTEND_USR_URL?lang=XX&token=JWT
  → core-frontend lê ?token= da URL
  → Decodifica JWT, salva no localStorage
  → App carrega autenticado
```

## Arquitetura (13 containers)

```
nginx (proxy :80)
  └─ gateway (Spring Cloud Gateway :8080)
       ├─ core-frontend (Vue.js/nginx :8080) → /
       ├─ auth-frontend (Vue.js/nginx :8080) → /auth/**
       ├─ core-backend (Spring Boot :8080) → /cardpgbackend/**
       ├─ auth-backend (Spring Boot :8081) → /auth-backend/**
       ├─ auth-keycloak (Keycloak 26 :8080) → /keycloak/**
       ├─ calc-engine (Spring WebFlux :8080) → /calculation-engine/**
       └─ geoserver (GeoServer :8080) → /geoserver/**

core-backend-db (PostgreSQL+PostGIS :5432)
authentication-db (PostgreSQL :5432)
calculator-engine-db (PostgreSQL :5432)
postgis-calculator-db (PostgreSQL+PostGIS :5432)
```

## Roteamento do Gateway

O gateway usa env vars para nomes de serviço (funciona em Docker Compose e K8s):

| Path | Destino | StripPrefix |
|------|---------|-------------|
| /keycloak/** | auth-keycloak:8080 | Não |
| /auth-backend/** | auth-backend:8081 | Sim (1) |
| /auth/** | auth-frontend:8080 | Não |
| /cardpgbackend/** | core-backend:8080 | Sim (1) |
| /calculation-engine/** | calc-engine:8080 | Sim (1) |
| /geoserver/** | geoserver:8080 | Não |
| /** (catch-all) | core-frontend:8080 | Não |

## Env Vars Críticas

### Gateway (application.yml usa Spring placeholders)
- `AUTHENTICATION_FRONTEND_SERVICE_NAME` — nome do service auth-frontend
- `AUTHENTICATION_BASE_KEYCLOAK_SERVICE_NAME` — nome do service keycloak
- `CORE_BACKEND_API_SERVICE_NAME` — nome do service core-backend
- `CORE_FRONTEND_SERVICE_NAME` — nome do service core-frontend

### Auth Frontend (build time)
- `VITE_BASE_URL=/auth/` — base path do SPA
- `VITE_KEYCLOAK_API_URL=/keycloak` — URL do Keycloak
- `VITE_BACKEND_API_URL=/auth-backend` — URL do auth-backend
- `VITE_FRONTEND_USR_URL=http://localhost/` — redirect pós-login (ABSOLUTA!)
- `VITE_REDIRECT_PARAMS_LANG=true` — enviar lang no redirect
- `VITE_REDIRECT_PARAMS_TOKEN=true` — enviar token no redirect

### Core Frontend (build time)
- `VITE_BASE_URL=/` — base path
- `VITE_AUTH_MODULE_URL=/auth` — URL do auth-frontend (redirect quando não autenticado)
- `VITE_GEOSERVER_URL=/geoserver/wms` — endpoint WMS do GeoServer (evita redirect 301 em `/geoserver`)

### Auth Backend (runtime)
- `KEYCLOAK_URL=http://authentication:8080/keycloak` — URL interna do Keycloak
- `SERVER_CONTEXT_PATH=/` — context path (default: / for standalone)

### Core Backend (runtime)
- `SERVER_SERVLET_CONTEXT_PATH=/cardpgbackend` — context path (default keeps backward compat)

## Builds Locais

Para desenvolvimento sem depender do ghcr.io:

```bash
# Core frontend (Vue.js)
cd frontend && podman build --build-arg VITE_BASE_URL=/ -t rer-core-frontend:local .

# Auth frontend (Vue.js)
cd authentication/frontend && podman build --build-arg BASE_PATH=/auth --build-arg VITE_BASE_URL=/auth/ -t rer-auth-frontend:local .

# Auth Keycloak
cd authentication && podman build -t rer-auth-keycloak:local .

# Core backend (Spring Boot)
cd backend && podman build -t rer-core-backend:local .

# Auth backend (Spring Boot)
cd authentication/cardpg && podman build -t rer-auth-backend:local .
```

## Correções Aplicadas (vs imagens ghcr.io originais)

1. **Frontend**: `VITE_BASE_URL=/` (era `/rectest/`)
2. **Auth frontend**: `VITE_BASE_URL=/auth/`, nginx try_files corrigido
3. **Keycloak**: `KC_HTTP_RELATIVE_PATH=/keycloak` (era `/rectest/keycloak`)
4. **Core backend**: `server.servlet.context-path` parametrizable via env (default `/cardpgbackend`)
5. **Auth backend**: `contextPath=/` + busca por email no credentials endpoint
6. **Gateway**: env vars para nomes de serviço + SPRING_CONFIG_LOCATION externo
7. **geoserver-init**: curl em vez de docker.sock (compatível Podman)

## Para K8s (Dataprev)

No K8s, os nomes de serviço são diferentes (ConfigMap `gateway-config`):
- `auth-frontend` (não `authentication-frontend`)
- `auth-keycloak` (não `authentication`)
- `auth-backend` (não `authentication-backend`)
- `calc-engine` (não `geo-calculation-engine-app`)

O gateway usa defaults que matcham K8s. O Docker Compose sobrescreve via env vars.
