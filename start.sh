#!/bin/bash
# This script is used to start the Docker Compose environment for the Car DPG project.
# It includes the core frontend and backend services.
# Usage: ./start.sh --<stage>

set -e
set -o pipefail

echo "Loading environment variables and preparing directories..."

#Main
export MAIN_PATH=.
export MAIN_CONFIG_PATH=./config/Main
export MAIN_PROXY_SERVICE_NAME=main-proxy
export MAIN_PROXY_CONTAINER_NAME=main-proxy
export DOLLAR='$'
# # Uncomment the following lines if you want to disable Docker BuildKit and CLI build
# export DOCKER_BUILDKIT=0
# export COMPOSE_DOCKER_CLI_BUILD=0

# Copy .env.example to .envs
cp $MAIN_CONFIG_PATH/environment/.env.example $MAIN_PATH/.env
# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Please create one based on .env.example."
    exit 1
fi

# Avoids dangerous redirects (e.g., > /.env) when path variables are empty.
validate_required_paths() {
    local missing=0
    local var

    for var in \
        CORE_FRONTEND_PATH CORE_FRONTEND_CONFIG_PATH \
        CORE_BACKEND_PATH CORE_BACKEND_CONFIG_PATH \
        AUTHENTICATION_PATH AUTHENTICATION_CONFIG_PATH \
        CALCULATION_ENGINE_PATH CALCULATION_ENGINE_CONFIG_PATH \
        GATEWAY_PATH GATEWAY_CONFIG_PATH \
        GEOSERVER_PATH GEOSERVER_CONFIG_PATH; do
        if [ -z "${!var:-}" ]; then
            echo "ERROR: ${var} is not defined or is empty."
            missing=1
        fi
    done

    if [ "$missing" -eq 1 ]; then
        exit 1
    fi
}
validate_required_paths

# Prepare Core_Frontend directory
envsubst < $CORE_FRONTEND_CONFIG_PATH/environment/.env | envsubst | envsubst | envsubst > $CORE_FRONTEND_PATH/.env
cp $CORE_FRONTEND_CONFIG_PATH/docker/Dockerfile $CORE_FRONTEND_PATH/Dockerfile
cp $CORE_FRONTEND_CONFIG_PATH/docker/.dockerignore $CORE_FRONTEND_PATH/.dockerignore
envsubst  < $CORE_FRONTEND_CONFIG_PATH/docker/docker-compose.yaml | envsubst | envsubst > $CORE_FRONTEND_PATH/docker-compose.yaml
envsubst  < $CORE_FRONTEND_CONFIG_PATH/nginx/nginx.conf.template > $CORE_FRONTEND_PATH/nginx.conf

# Ensure package-lock.json exists before Docker build (npm ci requires lock aligned with package.json)
ensure_map_component_package_lock() {
    local src="./map_component"

    if [ ! -d "$src" ]; then
        return 0
    fi

    if [ ! -f "$src/package-lock.json" ] || [ "$src/package.json" -nt "$src/package-lock.json" ]; then
        echo "WARNING: package-lock.json missing or outdated in map_component — regenerating..."
        if command -v npm >/dev/null 2>&1; then
            (cd "$src" && npm install --package-lock-only --ignore-scripts)
        elif command -v docker >/dev/null 2>&1; then
            docker run --rm -v "$(pwd)/$src:/app" -w /app node:18-alpine \
                npm install --package-lock-only --ignore-scripts
        elif command -v podman >/dev/null 2>&1; then
            podman run --rm -v "$(pwd)/$src:/app" -w /app node:18-alpine \
                npm install --package-lock-only --ignore-scripts
        else
            echo "ERROR: npm, docker or podman is required to generate package-lock.json."
            exit 1
        fi
    fi
}

# Sync map_component into frontend (excludes .git/node_modules to avoid permission errors on copy)
sync_map_component_to_frontend() {
    local src="./map_component"
    local dest="${CORE_FRONTEND_PATH}/map_component"

    if [ ! -d "$src" ]; then
        echo "ERROR: map_component folder not found at core root. Run ./setup.sh first."
        exit 1
    fi

    if command -v rsync >/dev/null 2>&1; then
        mkdir -p "$dest"
        rsync -a --delete \
            --exclude='.git' \
            --exclude='node_modules' \
            "$src/" "$dest/"
    else
        rm -rf "$dest"
        mkdir -p "$dest"
        (cd "$src" && tar --exclude='.git' --exclude='node_modules' -cf - .) | (cd "$dest" && tar -xf -)
    fi

    # Stale node_modules in dest (e.g. from Docker build) is not removed by rsync --exclude
    if [ -d "$dest/node_modules" ] && ! rm -rf "$dest/node_modules" 2>/dev/null; then
        echo "WARNING: could not remove ${dest}/node_modules (permission denied). .dockerignore prevents impact on Docker build."
    fi

    if [ ! -f "$dest/package-lock.json" ]; then
        echo "ERROR: package-lock.json not found in ${dest} after sync."
        echo "Run: cd map_component && npm install --package-lock-only"
        exit 1
    fi

    echo "map_component synced to ${dest} (without .git/node_modules)"
}
ensure_map_component_package_lock
sync_map_component_to_frontend

# Prepare Core_Backend directory
envsubst < $CORE_BACKEND_CONFIG_PATH/environment/.env.example | envsubst | envsubst | envsubst > $CORE_BACKEND_PATH/.env
cp -r $CORE_BACKEND_CONFIG_PATH/custom/images $CORE_BACKEND_PATH/src/main/resources
cp -r $CORE_BACKEND_CONFIG_PATH/custom/reports $CORE_BACKEND_PATH/src/main/resources
envsubst  < $CORE_BACKEND_CONFIG_PATH/docker/Dockerfile | envsubst | envsubst > $CORE_BACKEND_PATH/Dockerfile
envsubst  < $CORE_BACKEND_CONFIG_PATH/docker/docker-compose.yml | envsubst | envsubst > $CORE_BACKEND_PATH/docker-compose.yml
envsubst  < $CORE_BACKEND_CONFIG_PATH/application/application.properties | envsubst | envsubst > $CORE_BACKEND_PATH/src/main/resources/application.properties
envsubst  < $CORE_BACKEND_CONFIG_PATH/gradle/build.gradle > $CORE_BACKEND_PATH/build.gradle
envsubst  < $CORE_BACKEND_CONFIG_PATH/gradle/settings.gradle > $CORE_BACKEND_PATH/settings.gradle

# Prepare Authentication directory
cp ./.env $AUTHENTICATION_PATH/.env
envsubst < $AUTHENTICATION_CONFIG_PATH/frontend/environment/.env | envsubst | envsubst | envsubst > $AUTHENTICATION_PATH/frontend/.env
envsubst < $AUTHENTICATION_CONFIG_PATH/frontend/environment/.env | envsubst | envsubst | envsubst > $AUTHENTICATION_PATH/frontend/.env.production
envsubst < $AUTHENTICATION_CONFIG_PATH/frontend/docker/Dockerfile > $AUTHENTICATION_PATH/frontend/Dockerfile
envsubst  < $AUTHENTICATION_CONFIG_PATH/frontend/nginx/nginx.conf.template > $AUTHENTICATION_PATH/frontend/nginx.conf
envsubst < $AUTHENTICATION_CONFIG_PATH/backend/docker/Dockerfile > $AUTHENTICATION_PATH/cardpg/Dockerfile
envsubst < $AUTHENTICATION_CONFIG_PATH/backend/application/application.yml | envsubst | envsubst | envsubst > $AUTHENTICATION_PATH/cardpg/src/main/resources/application.yml
envsubst  < $AUTHENTICATION_CONFIG_PATH/docker/docker-compose.yml | envsubst | envsubst | envsubst > $AUTHENTICATION_PATH/docker-compose.yml
envsubst  < $AUTHENTICATION_CONFIG_PATH/docker/Dockerfile > $AUTHENTICATION_PATH/Dockerfile

#Prepare Calculation Engine directory
envsubst  < $CALCULATION_ENGINE_CONFIG_PATH/docker/docker-compose.yml | envsubst | envsubst | envsubst > $CALCULATION_ENGINE_PATH/docker-compose.yml
envsubst < $CALCULATION_ENGINE_CONFIG_PATH/docker/Dockerfile > $CALCULATION_ENGINE_PATH/Dockerfile
envsubst  < $CALCULATION_ENGINE_CONFIG_PATH/application/application.properties | envsubst | envsubst > $CALCULATION_ENGINE_PATH/src/main/resources/application.properties
envsubst  < $CALCULATION_ENGINE_CONFIG_PATH/maven/pom.xml > $CALCULATION_ENGINE_PATH/pom.xml

# Prepare Main directory
if [ -z "$BASE_URL" ]; then
    envsubst < $MAIN_CONFIG_PATH/nginx/nginx.conf.template | sed "s#^.*X-Forwarded-Prefix.*\$##g" > $MAIN_PATH/nginx.conf
else
    envsubst < $MAIN_CONFIG_PATH/nginx/nginx.conf.template > $MAIN_PATH/nginx.conf
fi
envsubst  < $MAIN_CONFIG_PATH/docker/docker-compose.yaml | envsubst | envsubst | envsubst > $MAIN_PATH/docker-compose.yaml
cp $MAIN_CONFIG_PATH/docker/Dockerfile.proxy $MAIN_PATH/Dockerfile.proxy

#Prepare Gateway directory
envsubst < $GATEWAY_CONFIG_PATH/docker/Dockerfile > $GATEWAY_PATH/Dockerfile
envsubst < $GATEWAY_CONFIG_PATH/docker/docker-compose.yml | envsubst | envsubst > $GATEWAY_PATH/docker-compose.yml
envsubst  < $GATEWAY_CONFIG_PATH/maven/pom.xml > $GATEWAY_PATH/pom.xml
mkdir -p $GATEWAY_PATH/src/main/resources
envsubst < $GATEWAY_CONFIG_PATH/application/application.yml > $GATEWAY_PATH/src/main/resources/application.yml

#Prepare Geoserver directory
mkdir -p $GEOSERVER_PATH
envsubst < $GEOSERVER_CONFIG_PATH/docker/docker-compose.yml | envsubst | envsubst > $GEOSERVER_PATH/docker-compose.yml
cp $GEOSERVER_CONFIG_PATH/docker/Dockerfile $GEOSERVER_PATH/Dockerfile
cp $GEOSERVER_CONFIG_PATH/docker/populate_geoserver.sh $GEOSERVER_PATH/populate_geoserver.sh
cp $GEOSERVER_CONFIG_PATH/docker/docker-entrypoint.sh $GEOSERVER_PATH/docker-entrypoint.sh

# Proxy configuration
if [ -z "$PROXY_HOST" ] || [ -z "$PROXY_PORT" ]; then
    echo "PROXY_HOST or PROXY_PORT is not set, skipping proxy configuration."
    echo "<settings></settings>" > $CALCULATION_ENGINE_PATH/settings.xml
    echo "<settings></settings>" > $AUTHENTICATION_PATH/cardpg/settings.xml
    echo "<settings></settings>" > $GATEWAY_PATH/settings.xml
else
    envsubst < $CALCULATION_ENGINE_CONFIG_PATH/application/settings.xml > $CALCULATION_ENGINE_PATH/settings.xml
    envsubst < $AUTHENTICATION_CONFIG_PATH/backend/application/settings.xml > $AUTHENTICATION_PATH/cardpg/settings.xml
    envsubst < $GATEWAY_CONFIG_PATH/application/settings.xml > $GATEWAY_PATH/settings.xml
fi

echo "Environment variables loaded and directories prepared successfully."

echo "Starting Docker Compose environment for RER DPG project..."
#Build and run the Docker Compose environment
# # Uncomment the following lines to build without cache and show progress
docker compose -f docker-compose.yaml build --progress=plain --no-cache
docker compose -f docker-compose.yaml up --force-recreate -d --remove-orphans
echo "Docker Compose environment started successfully."
