# ============================
# Imagem base do Keycloak
# ============================
# Imagem oficial 26.8.2-3: Red Hat OpenJDK 21.0.13.1 (corrige a CVE-2026-114938, Java4Shell).
FROM quay.io/keycloak/keycloak:26.8.2-3

# ============================
# Copiar temas e providers
# ============================
COPY themes /opt/keycloak/themes
COPY providers /opt/keycloak/providers

# ============================
# Configurações de cache
# ============================
ENV KC_SPI_THEME_CACHE_THEMES=false
ENV KC_SPI_THEME_CACHE_TEMPLATES=false

# ============================
# Configuração do banco
# ============================
ENV KC_DB=postgres

# ============================
# Features experimentais
# ============================
ENV KC_FEATURES=preview

# ============================
# Context path da aplicação
# ============================
ENV KC_HTTP_RELATIVE_PATH=${BASE_URL}${AUTHENTICATION_BASE_KEYCLOAK_BASE_URL}

# ============================
# Configurações de proxy
# ============================
ENV KC_PROXY=passthrough
ENV PROXY_ADDRESS_FORWARDING=true
ENV KC_PROXY_HEADERS=xforwarded
ENV KC_PROXY=edge

# ============================
# Habilitar HTTP
# ============================
ENV KC_HTTP_ENABLED=true
  
# ============================
# Arquivo de importação
# ============================
COPY ./keycloak-import/realm-export.json /opt/keycloak/data/import/realm-export.json

# ============================
# Build do Keycloak
# ============================
RUN /opt/keycloak/bin/kc.sh build --features=scripts
