#!/bin/bash
# Ajusta permissões do data dir (volume pode ter sido criado como root).
# Roda como root antes do startup.sh oficial (RUN_UNPRIVILEGED → UID 999).
set -e

GEOSERVER_UID="${RUN_WITH_USER_UID:-${GEOSERVER_UID:-999}}"
GEOSERVER_GID="${RUN_WITH_USER_GID:-${GEOSERVER_GID:-999}}"
DATA_DIR="${GEOSERVER_DATA_DIR:-/var/geoserver/datadir}"

mkdir -p "$DATA_DIR"
if [ "$(id -u)" -eq 0 ]; then
    chown -R "${GEOSERVER_UID}:${GEOSERVER_GID}" "$DATA_DIR"
fi

exec /opt/startup.sh "$@"
