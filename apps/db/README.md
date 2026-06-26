# PostgreSQL local — FacturaOn

Base de datos PostgreSQL en Docker para desarrollo local. La API (`api-firma`) se conecta por la red compartida **`fon-net`** al contenedor `fon-postgres`.

## Requisitos

- Docker y Docker Compose
- Un archivo `.sql` de respaldo en `dumps/` (ver abajo)

## Configuración inicial

```bash
cd apps/db
cp .env.example .env
```

Colocar el respaldo en:

```
dumps/respaldo_fon23_dev.sql
```

O definir otra ruta en `.env`:

```env
LOCAL_DUMP_FILE=dumps/mi_respaldo.sql
```

| Variable | Descripción |
|----------|-------------|
| `POSTGRES_*` | Credenciales de la BD local |
| `LOCAL_DUMP_FILE` | Ruta al respaldo a restaurar |
| `DUMP_REMOTE_ROLES` | Roles del dump (ej. `postgres,user_fon23_dev`) reescritos a `POSTGRES_USER` |
| `REMOTE_DB_*` | Solo si usa `--fetch-remote` o `dump-from-remote.sh` |

## Primer arranque (respaldo local → PostgreSQL)

```bash
cd apps/db
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

Esto:

1. Levanta `fon-postgres` en el puerto **5432**
2. Restaura `dumps/respaldo_fon23_dev.sql` (o `LOCAL_DUMP_FILE`) en `fon23_dev`

Los respaldos en `dumps/` están ignorados por git (salvo `.gitkeep`).

## Comandos útiles

```bash
cd apps/db

# Solo levantar / bajar PostgreSQL
docker compose up -d
docker compose down

# Esperar a que esté listo
./scripts/wait-for-postgres.sh

# Restaurar el respaldo configurado (o uno específico)
./scripts/restore-local.sh
./scripts/restore-local.sh dumps/otro_respaldo.sql

# Bootstrap completo (mismo flujo que el primer arranque)
./scripts/bootstrap.sh

# Actualizar desde el servidor remoto y restaurar
./scripts/bootstrap.sh --fetch-remote

# Solo descargar del remoto (crea dumps/latest.sql)
./scripts/dump-from-remote.sh

# Logs
docker compose logs -f
docker logs -f fon-postgres
```

## Prioridad al elegir el respaldo

`restore-local.sh` y `bootstrap.sh` buscan en este orden:

1. Archivo pasado con `--file` o como argumento
2. `LOCAL_DUMP_FILE` en `.env`
3. `dumps/respaldo_fon23_dev.sql`
4. `dumps/latest.sql` (symlink creado por `dump-from-remote.sh`)
5. Cualquier otro `.sql` en `dumps/`

## Conectar la API

En `apps/api-firma/.env`:

```env
DB_HOST=fon-postgres
DB_PORT=5432
DB_NAME=fon23_dev
DB_USERNAME=fon
DB_PASSWORD=fon_local_dev
```

Luego (con la BD ya levantada):

```bash
cd apps/api-firma
docker compose up -d
```

**Orden recomendado:** primero `apps/db`, después `apps/api-firma`.

## Red Docker

| Contenedor | Red | Hostname interno |
|------------|-----|------------------|
| `fon-postgres` | `fon-net` | `fon-postgres` |
| `facturaon-api` | `fon-net` (externa) | — |

La red `fon-net` la crea este compose al hacer `docker compose up`.

## Scripts SQL manuales

Cambios DDL que no pasan por migraciones Rails:

```
manual/
├── audit_events.sql
└── onboarding_tokens_restablecer_password.sql
```

Ejemplo de ejecución local:

```bash
docker compose exec -T postgres psql -U fon -d fon23_dev < manual/audit_events.sql
```

## Acceso directo con psql

Desde el host:

```bash
psql -h localhost -p 5432 -U fon -d fon23_dev
```

Desde Docker:

```bash
docker compose exec postgres psql -U fon -d fon23_dev
```

## Reinicio limpio (borrar datos locales)

```bash
docker compose down -v
./scripts/bootstrap.sh
```

`-v` elimina el volumen `fon_pg_data`; el próximo `up` recrea la BD vacía antes del restore.

## Notas

- Los dumps descargados del remoto usan `--no-owner --no-acl` (sin roles extra).
- Respaldos manuales pueden traer `OWNER TO postgres` o `user_fon23_dev`; el restore los reasigna a `POSTGRES_USER`.
- `dumps/latest.sql` es un symlink al último respaldo generado por `dump-from-remote.sh`.
- No commitear `.env` ni archivos en `dumps/`.
