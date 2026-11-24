# ============================
# 1) Dependencies Stage
# ============================
FROM gradle:8.12.1-jdk21 AS dependencies
WORKDIR /app

ENV GRADLE_OPTS="-Dhttps.proxyHost=${PROXY_HOST} -Dhttps.proxyPort=${PROXY_PORT} -Dhttp.proxyHost=${PROXY_HOST} -Dhttp.proxyPort=${PROXY_PORT}"

# Copiar arquivos de configuração do Gradle
COPY build.gradle settings.gradle gradle.properties* gradlew gradlew.bat ./
COPY gradle/ ./gradle/

# Download dependencies com cache - esta camada será reutilizada
RUN --mount=type=cache,target=/root/.gradle/caches \
    --mount=type=cache,target=/root/.gradle/wrapper \
    chmod +x ./gradlew && \
    (./gradlew dependencies --no-daemon || gradle dependencies --no-daemon)

# ============================
# 2) Build Stage
# ============================
FROM dependencies AS build

# Copiar código fonte
COPY src/ ./src/

# Build com cache otimizado
RUN --mount=type=cache,target=/root/.gradle/caches \
    --mount=type=cache,target=/root/.gradle/wrapper \
    ./gradlew clean compileJasperReports copyCompiledJasper build -x test --no-daemon

# ============================
# 3) Runtime Stage
# ============================
FROM eclipse-temurin:21.0.13.1_2-jre-jammy AS runtime
WORKDIR /app

# Atualizar sistema e instalar dependências
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    libfreetype6 \
    fontconfig \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copiar JAR do estágio anterior
COPY --from=build /app/build/libs/${CORE_BACKEND_PROJECT_NAME}-${CORE_BACKEND_VERSION}.jar /app/app.jar

# Configurações JVM otimizadas
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]