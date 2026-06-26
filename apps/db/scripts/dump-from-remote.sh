#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/_lib.sh"
load_db_env

require_var REMOTE_DB_HOST
require_var REMOTE_DB_PORT
require_var REMOTE_DB_NAME
require_var REMOTE_DB_USERNAME
require_var REMOTE_DB_PASSWORD

mkdir -p dumps

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DUMP_BASENAME="fon23_dev_${TIMESTAMP}.sql"
DUMP_PATH="dumps/${DUMP_BASENAME}"

echo "Generando respaldo desde ${REMOTE_DB_HOST}/${REMOTE_DB_NAME}…"

docker run --rm \
  -e PGPASSWORD="$REMOTE_DB_PASSWORD" \
  -v "$(pwd)/dumps:/dumps" \
  postgres:16-alpine \
  pg_dump \
    -h "$REMOTE_DB_HOST" \
    -p "$REMOTE_DB_PORT" \
    -U "$REMOTE_DB_USERNAME" \
    -d "$REMOTE_DB_NAME" \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    -f "/dumps/${DUMP_BASENAME}"

ln -sfn "$DUMP_BASENAME" dumps/latest.sql

echo "Respaldo guardado en ${DUMP_PATH}"
echo "Enlace actualizado: dumps/latest.sql -> ${DUMP_BASENAME}"
