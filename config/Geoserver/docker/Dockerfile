FROM docker.osgeo.org/geoserver:2.28.0
# CVE-2026-114938: substitui o JDK embarcado (Temurin 17.0.16) pelo 17.0.21.1 corrigido.
# Remover quando a imagem oficial trouxer JDK corrigido.
COPY --from=eclipse-temurin:17.0.21.1_2-jre-noble /opt/java/openjdk /opt/java/openjdk

# Instalar dependências necessárias
USER root
RUN apt-get update --allow-insecure-repositories --allow-unauthenticated && \
    apt-get install -y --no-install-recommends --allow-unauthenticated \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# UID 999 = usuário tomcat no modo RUN_UNPRIVILEGED (alinhado ao docker-compose)
RUN mkdir -p /opt/additional_libs /opt/geoserver_data /var/geoserver/datadir && \
    chown -R 999:999 /opt/additional_libs \
                    /opt/geoserver_data \
                    /var/geoserver/datadir \
                    /opt/startup.sh \
                    /usr/local/tomcat/conf \
                    /usr/local/tomcat/webapps \
                    /usr/local/tomcat/logs \
                    /usr/local/tomcat/temp \
                    /usr/local/tomcat/work && \
    chmod -R 775 /var/geoserver/datadir /opt/additional_libs

COPY populate_geoserver.sh /opt/populate_geoserver.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /opt/populate_geoserver.sh /docker-entrypoint.sh && \
    chown 999:999 /opt/populate_geoserver.sh /docker-entrypoint.sh

# Entrypoint roda como root; startup.sh aplica RUN_UNPRIVILEGED e rebaixa para UID 999
ENV GEOSERVER_DATA_DIR=/var/geoserver/datadir

ENTRYPOINT ["/docker-entrypoint.sh"]
