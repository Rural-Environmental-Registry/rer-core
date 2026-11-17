#!/bin/bash
# Carrega malhas territoriais IBGE (país, UF, município) no car_db.
# Fonte única dos dados territoriais: GeoServer publica WMS a partir destas tabelas
# (populate_geoserver.sh --ibge-layers), após este script no start.sh.
#
# Uso:
#   ./config/Core-Backend/scripts/load_ibge_territorial_data.sh
#   ./config/Core-Backend/scripts/load_ibge_territorial_data.sh --force

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

FORCE_RELOAD=0
if [ "${1:-}" = "--force" ]; then
    FORCE_RELOAD=1
fi

# Carrega .env da raiz do core, se existir
if [ -f "$CORE_ROOT/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$CORE_ROOT/.env"
    set +a
fi

DB_HOST="${CORE_BACKEND_DB_SERVICE_NAME:-core-backend-db}"
DB_CONTAINER="${CORE_BACKEND_DB_CONTAINER_NAME:-core-backend-db}"
DB_NAME="${CORE_BACKEND_DB_NAME:-car_db}"
DB_USER="${CORE_BACKEND_DB_USER:-car_user}"
DB_PASSWORD="${CORE_BACKEND_DB_PASSWORD:-car_pass}"

PAIS_URL="https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_Pais_2024.zip"
UF_URL="https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_UF_2024.zip"
MUNICIPIOS_URL="https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2024/Brasil/BR_Municipios_2024.zip"

# postgis/postgis não inclui ogr2ogr; usar imagem GDAL com driver PostgreSQL
OGR_IMAGE="${OGR_IMAGE:-ghcr.io/osgeo/gdal:alpine-small-3.10.2}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-300}"

info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Comando obrigatório não encontrado: $1"
        exit 1
    fi
}

resolve_db_network() {
    local network
    network="$(docker inspect -f '{{range $name, $cfg := .NetworkSettings.Networks}}{{$name}} {{end}}' "$DB_CONTAINER" 2>/dev/null || true)"
    for net in $network; do
        if [[ "$net" == *core-backend* ]]; then
            echo "$net"
            return 0
        fi
    done
    # fallback: primeira rede do container
    echo "$network" | awk '{print $1}'
}

psql_exec() {
    docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_CONTAINER" \
        psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME" -tAc "$1"
}

wait_for_database() {
    local elapsed=0
    info "Aguardando banco $DB_CONTAINER..."
    while [ "$elapsed" -lt "$MAX_WAIT_SECONDS" ]; do
        if docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    error "Timeout aguardando PostgreSQL em $DB_CONTAINER"
    exit 1
}

wait_for_tables() {
    local elapsed=0
    info "Aguardando tabelas territoriais (Flyway)..."
    while [ "$elapsed" -lt "$MAX_WAIT_SECONDS" ]; do
        local exists
        exists="$(psql_exec "SELECT to_regclass('public.country') IS NOT NULL AND to_regclass('public.state') IS NOT NULL AND to_regclass('public.municipality') IS NOT NULL;" 2>/dev/null || echo "f")"
        if [ "$exists" = "t" ]; then
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    error "Timeout aguardando tabelas country/state/municipality. Verifique se o core-backend subiu e aplicou Flyway."
    exit 1
}

download_ibge_zip() {
    local url="$1"
    local output="$2"
    if [ -f "$output" ]; then
        info "ZIP já existe: $output"
        return 0
    fi
    info "Baixando $output..."
    curl -fsSL -o "$output" "$url"
}

unzip_ibge() {
    local zip_file="$1"
    local dest_dir="$2"
    mkdir -p "$dest_dir"
    if [ -n "$(find "$dest_dir" -maxdepth 1 -name '*.shp' -print -quit 2>/dev/null)" ]; then
        info "Shapefile já extraído em $dest_dir"
        return 0
    fi
    unzip -o -q "$zip_file" -d "$dest_dir"
}

import_shapefile() {
    local shp_path="$1"
    local table_name="$2"
    local sql_query="$3"
    local network="$4"
    local pg_conn="PG:host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASSWORD}"

    info "Importando $table_name a partir de $(basename "$shp_path")..."
    docker run --rm \
        --entrypoint '' \
        --network "$network" \
        -v "$(dirname "$shp_path"):/data:ro" \
        "$OGR_IMAGE" \
        ogr2ogr -f PostgreSQL "$pg_conn" \
            "/data/$(basename "$shp_path")" \
            -nln "$table_name" \
            -append \
            -lco GEOMETRY_NAME=geometry \
            -nlt PROMOTE_TO_MULTI \
            -sql "$sql_query"
}

validate_counts() {
    local country_count state_count municipality_count
    country_count="$(psql_exec "SELECT COUNT(*) FROM country;")"
    state_count="$(psql_exec "SELECT COUNT(*) FROM state;")"
    municipality_count="$(psql_exec "SELECT COUNT(*) FROM municipality;")"

    info "Registros carregados: country=$country_count, state=$state_count, municipality=$municipality_count"

    if [ "$country_count" -lt 1 ]; then
        error "Carga incompleta: country deve ter ao menos 1 registro."
        exit 1
    fi
    if [ "$state_count" -ne 27 ]; then
        error "Carga incompleta: state deve ter 27 registros (encontrado: $state_count)."
        exit 1
    fi
    if [ "$municipality_count" -lt 5000 ]; then
        error "Carga incompleta: municipality deve ter mais de 5000 registros (encontrado: $municipality_count)."
        exit 1
    fi
}

main() {
    require_command curl
    require_command unzip
    require_command docker

    if ! docker inspect "$DB_CONTAINER" >/dev/null 2>&1; then
        error "Container do banco não encontrado: $DB_CONTAINER"
        exit 1
    fi

    local network
    network="$(resolve_db_network)"
    if [ -z "$network" ]; then
        error "Não foi possível resolver a rede Docker do container $DB_CONTAINER"
        exit 1
    fi
    info "Rede Docker: $network"

    wait_for_database
    wait_for_tables

    local counts country_count state_count municipality_count
    counts="$(psql_exec "SELECT (SELECT COUNT(*) FROM country), (SELECT COUNT(*) FROM state), (SELECT COUNT(*) FROM municipality);")"
    IFS='|' read -r country_count state_count municipality_count <<< "$counts"
    country_count="${country_count//[^0-9]/}"
    state_count="${state_count//[^0-9]/}"
    municipality_count="${municipality_count//[^0-9]/}"

    if [ -z "$country_count" ] || [ -z "$state_count" ] || [ -z "$municipality_count" ]; then
        error "Não foi possível ler a quantidade de registros em country, state e municipality."
        exit 1
    fi

    if [ "$FORCE_RELOAD" -eq 0 ] \
        && [ "$country_count" -gt 0 ] \
        && [ "$state_count" -gt 0 ] \
        && [ "$municipality_count" -gt 0 ]; then
        info "Tabelas territoriais já possuem dados (country=$country_count, state=$state_count, municipality=$municipality_count)."
        info "Download dos arquivos IBGE não será feito."
        exit 0
    fi

    if [ "$FORCE_RELOAD" -eq 1 ]; then
        info "Recarregando dados (--force): truncando tabelas..."
        psql_exec "TRUNCATE TABLE municipality, state, country RESTART IDENTITY;"
    fi

    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    download_ibge_zip "$PAIS_URL" "$TEMP_DIR/BR_Pais_2024.zip"
    download_ibge_zip "$UF_URL" "$TEMP_DIR/BR_UF_2024.zip"
    download_ibge_zip "$MUNICIPIOS_URL" "$TEMP_DIR/BR_Municipios_2024.zip"

    unzip_ibge "$TEMP_DIR/BR_Pais_2024.zip" "$TEMP_DIR/pais"
    unzip_ibge "$TEMP_DIR/BR_UF_2024.zip" "$TEMP_DIR/uf"
    unzip_ibge "$TEMP_DIR/BR_Municipios_2024.zip" "$TEMP_DIR/municipios"

    local shp_pais shp_uf shp_mun
    shp_pais="$(find "$TEMP_DIR/pais" -maxdepth 2 -name 'BR_Pais_2024.shp' | head -n 1)"
    shp_uf="$(find "$TEMP_DIR/uf" -maxdepth 2 -name 'BR_UF_2024.shp' | head -n 1)"
    shp_mun="$(find "$TEMP_DIR/municipios" -maxdepth 2 -name 'BR_Municipios_2024.shp' | head -n 1)"

    if [ -z "$shp_pais" ] || [ -z "$shp_uf" ] || [ -z "$shp_mun" ]; then
        error "Shapefile IBGE não encontrado após extração."
        exit 1
    fi

    import_shapefile "$shp_pais" "country" \
        "SELECT PAIS AS country, AREA_KM2 AS area_km2 FROM BR_Pais_2024" \
        "$network"

    local country_id
    country_id="$(psql_exec "SELECT id FROM country ORDER BY id LIMIT 1;")"
    if [ -z "$country_id" ]; then
        error "Não foi possível obter o id do país após a importação."
        exit 1
    fi
    info "País carregado com id=$country_id. As UFs serão vinculadas a esse country_id."

    # Shapefile DBF limita o nome do campo a 10 caracteres: CD_REGIAO vira CD_REGIA.
    import_shapefile "$shp_uf" "state" \
        "SELECT ${country_id} AS country_id, CD_UF AS cd_uf, NM_UF AS nm_uf, SIGLA_UF AS sigla_uf, CD_REGIA AS cd_regiao, NM_REGIA AS nm_regiao, SIGLA_RG AS sigla_rg, AREA_KM2 AS area_km2 FROM BR_UF_2024" \
        "$network"

    import_shapefile "$shp_mun" "municipality" \
        "SELECT CD_MUN AS cd_mun, NM_MUN AS nm_mun, CD_UF AS cd_uf, NM_UF AS nm_uf, SIGLA_UF AS sigla_uf, CD_REGIA AS cd_regiao, NM_REGIA AS nm_regiao, SIGLA_RG AS sigla_rg, AREA_KM2 AS area_km2 FROM BR_Municipios_2024" \
        "$network"

    validate_counts
    info "Carga territorial IBGE concluída com sucesso."
}

main "$@"
