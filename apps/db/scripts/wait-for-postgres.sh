#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/_lib.sh"
load_db_env

require_var POSTGRES_USER
require_var POSTGRES_DB

MAX_ATTEMPTS="${1:-30}"
ATTEMPT=0

until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [[ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]]; then
    echo "Error: PostgreSQL no respondió a tiempo." >&2
    exit 1
  fi
  sleep 2
done

echo "PostgreSQL listo ($POSTGRES_DB)."
