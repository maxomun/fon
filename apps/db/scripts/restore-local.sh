#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/_lib.sh"
load_db_env

require_var POSTGRES_USER
require_var POSTGRES_PASSWORD
require_var POSTGRES_DB

if ! DUMP_FILE="$(resolve_dump_file "${1:-}")"; then
  echo "Error: no se encontró ningún respaldo .sql en dumps/." >&2
  echo "" >&2
  echo "Coloque un archivo en dumps/respaldo_fon23_dev.sql" >&2
  echo "o defina LOCAL_DUMP_FILE en apps/db/.env" >&2
  echo "o ejecute: ./scripts/dump-from-remote.sh" >&2
  exit 1
fi

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "Error: no existe el archivo de respaldo: $DUMP_FILE" >&2
  exit 1
fi

"$(dirname "$0")/wait-for-postgres.sh"

echo "Restaurando respaldo en PostgreSQL local (${POSTGRES_DB})…"
echo "Archivo: $DUMP_FILE"

# Recrear la base para evitar objetos huérfanos entre restauraciones.
docker compose exec -T postgres psql -U "$POSTGRES_USER" -d postgres <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${POSTGRES_DB}'
  AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS ${POSTGRES_DB};
CREATE DATABASE ${POSTGRES_DB};
SQL

docker compose exec -T postgres psql \
  -v ON_ERROR_STOP=1 \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  < <(prepare_dump_stream "$DUMP_FILE" "$POSTGRES_USER")

echo "Restauración completada en ${POSTGRES_DB}."
