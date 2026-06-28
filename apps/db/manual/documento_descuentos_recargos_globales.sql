-- Descuentos/recargos globales por documento emitido (F6).
-- Ejecutar manualmente si la BD aún no tiene esta tabla.
--
-- Ejemplo (local):
--   docker compose exec -T postgres psql -U fon -d fon_dev -f - < apps/db/manual/documento_descuentos_recargos_globales.sql

BEGIN;

CREATE TABLE IF NOT EXISTS documento_descuentos_recargos_globales (
  id SERIAL PRIMARY KEY,
  documento_emitido_id INTEGER NOT NULL,
  nro_linea INTEGER NOT NULL,
  tipo_movimiento VARCHAR(1) NOT NULL,
  glosa VARCHAR(250) NOT NULL,
  tipo_valor VARCHAR(20) NOT NULL,
  valor NUMERIC(15, 4) NOT NULL,
  aplica_sobre VARCHAR(30) NOT NULL,
  monto_calculado INTEGER NOT NULL,
  orden INTEGER NOT NULL
);

COMMENT ON TABLE documento_descuentos_recargos_globales IS
  'Descuentos/recargos globales DTE por documento emitido (SII DscRcgGlobal).';

CREATE INDEX IF NOT EXISTS idx_doc_dr_globales_documento
  ON documento_descuentos_recargos_globales (documento_emitido_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_doc_dr_globales_documento_nro_linea
  ON documento_descuentos_recargos_globales (documento_emitido_id, nro_linea);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_doc_dr_globales_documento_emitidos'
  ) THEN
    ALTER TABLE documento_descuentos_recargos_globales
      ADD CONSTRAINT fk_doc_dr_globales_documento_emitidos
      FOREIGN KEY (documento_emitido_id)
      REFERENCES documento_emitidos (id)
      ON DELETE CASCADE;
  END IF;
END $$;

COMMIT;
