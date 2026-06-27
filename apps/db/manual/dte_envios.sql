-- Envíos DTE: agrupa el XML firmado (Active Storage) con uno o más documento_emitidos.
-- Ejecutar manualmente si la BD aún no tiene estas estructuras.
--
-- Ejemplo (local):
--   docker compose exec -T postgres psql -U fon -d fon_dev -f - < ../db/manual/dte_envios.sql
--
-- Rollback:
--   ALTER TABLE documento_emitidos DROP COLUMN IF EXISTS dte_envio_id;
--   DROP TABLE IF EXISTS dte_envios;

BEGIN;

CREATE TABLE IF NOT EXISTS dte_envios (
  id         SERIAL PRIMARY KEY,
  empresa_id INTEGER NOT NULL REFERENCES empresas(id),
  usuario_id INTEGER NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dte_envios_empresa_created
  ON dte_envios (empresa_id, created_at DESC);

ALTER TABLE documento_emitidos
  ADD COLUMN IF NOT EXISTS dte_envio_id INTEGER REFERENCES dte_envios(id);

CREATE INDEX IF NOT EXISTS idx_documento_emitidos_dte_envio
  ON documento_emitidos (dte_envio_id);

COMMIT;
