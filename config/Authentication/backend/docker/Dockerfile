# ============================
# 1) Dependencies Stage
# ============================
FROM maven:3.9.8-eclipse-temurin-21-alpine AS dependencies

ENV http_proxy=$HTTP_PROXY \
    https_proxy=$HTTPS_PROXY \
    no_proxy=$NO_PROXY

WORKDIR /app

# Copiar apenas arquivos de configuração Maven primeiro
COPY pom.xml ./
COPY settings.xml /root/.m2/settings.xml

# Download dependencies com cache - esta camada será reutilizada
RUN --mount=type=cache,target=/root/.m2/repository \
    mvn dependency:go-offline -B --no-transfer-progress

# ============================
# 2) Build Stage
# ============================
FROM dependencies AS build

# Copiar código fonte
COPY src ./src

# Build com cache otimizado
RUN --mount=type=cache,target=/root/.m2/repository \
    mvn clean package -DskipTests --no-transfer-progress -q

# ============================
# 3) Runtime Stage
# ============================
FROM eclipse-temurin:21.0.13.1_2-jre-alpine AS runtime

# Atualizar pacotes para corrigir CVEs
RUN apk update && apk upgrade --no-cache

WORKDIR /app

# Instalar dependências necessárias
RUN apk add --no-cache \
    fontconfig \
    ttf-dejavu

# Criar usuário não-root
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copiar JAR
COPY --from=build /app/target/*.jar app.jar

# Configurar permissões
RUN chown appuser:appgroup app.jar

# Configurações JVM otimizadas
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"

EXPOSE 8081
USER appuser

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]