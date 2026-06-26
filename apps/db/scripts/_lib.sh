#!/usr/bin/env bash
set -euo pipefail

load_db_env() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  cd "$root"

  if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  else
    echo "Error: no existe apps/db/.env (copie desde .env.example)." >&2
    exit 1
  fi
}

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Error: falta la variable $name en apps/db/.env" >&2
    exit 1
  fi
}

# Resuelve qué archivo .sql restaurar (prioridad: argumento > .env > convenciones).
resolve_dump_file() {
  local explicit="${1:-}"

  if [[ -n "$explicit" ]]; then
    echo "$explicit"
    return 0
  fi

  if [[ -n "${LOCAL_DUMP_FILE:-}" && -f "$LOCAL_DUMP_FILE" ]]; then
    echo "$LOCAL_DUMP_FILE"
    return 0
  fi

  if [[ -f dumps/respaldo_fon23_dev.sql ]]; then
    echo dumps/respaldo_fon23_dev.sql
    return 0
  fi

  if [[ -e dumps/latest.sql ]]; then
    echo dumps/latest.sql
    return 0
  fi

  local candidate
  candidate="$(find dumps -maxdepth 1 -type f -name '*.sql' 2>/dev/null | sort | head -n 1)"
  if [[ -n "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  return 1
}

# Reescribe OWNER TO de roles del dump remoto al usuario local (POSTGRES_USER).
prepare_dump_stream() {
  local dump_file="$1"
  local local_user="$2"
  local remote_roles="${DUMP_REMOTE_ROLES:-postgres,user_fon23_dev}"

  local sed_args=()
  local role

  IFS=',' read -ra role_list <<< "$remote_roles"
  for role in "${role_list[@]}"; do
    role="${role#"${role%%[![:space:]]*}"}"
    role="${role%"${role##*[![:space:]]}"}"
    if [[ -z "$role" || "$role" == "$local_user" ]]; then
      continue
    fi
    sed_args+=(-e "s/OWNER TO ${role}/OWNER TO ${local_user}/g")
  done

  if [[ ${#sed_args[@]} -eq 0 ]]; then
    cat "$dump_file"
  else
    sed "${sed_args[@]}" "$dump_file"
  fi
}
