#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/_lib.sh"
load_db_env

FETCH_REMOTE=false
DUMP_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fetch-remote)
      FETCH_REMOTE=true
      shift
      ;;
    --file)
      DUMP_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Uso: ./scripts/bootstrap.sh [opciones]

Levanta PostgreSQL local y restaura un respaldo en la base local.

Por defecto usa el archivo en dumps/ (LOCAL_DUMP_FILE o respaldo_fon23_dev.sql).
No descarga del remoto salvo que pase --fetch-remote.

Opciones:
  --fetch-remote  Descargar respaldo del servidor remoto antes de restaurar
  --file PATH     Restaurar un archivo .sql específico
  -h, --help      Mostrar esta ayuda
EOF
      exit 0
      ;;
    *)
      echo "Opción desconocida: $1" >&2
      exit 1
      ;;
  esac
done

echo "Levantando PostgreSQL local…"
docker compose up -d
"$(dirname "$0")/wait-for-postgres.sh"

if [[ "$FETCH_REMOTE" == true ]]; then
  "$(dirname "$0")/dump-from-remote.sh"
fi

if [[ -n "$DUMP_FILE" ]]; then
  "$(dirname "$0")/restore-local.sh" "$DUMP_FILE"
else
  "$(dirname "$0")/restore-local.sh"
fi

echo ""
echo "Bootstrap completado."
echo "Siguiente paso: en apps/api-firma configure .env con DB_HOST=fon-postgres y levante la API."
