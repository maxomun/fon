-- Referencias SII (<Referencia>) asociadas a un documento emitido.
-- Ejecutar DESPUÉS de tipo_referencia_documentos.sql
--
-- Ejemplo (local):
--   psql -h localhost -U fon -d fon23_dev -f apps/db/manual/documento_emitido_referencias.sql

BEGIN;

CREATE TABLE IF NOT EXISTS documento_emitido_referencias (
  id SERIAL PRIMARY KEY,
  documento_emitido_id INTEGER NOT NULL,
  nro_linea INTEGER NOT NULL,
  tipo_referencia_documento_id INTEGER NOT NULL,
  folio_referencia VARCHAR(18) NOT NULL,
  fecha_referencia DATE NOT NULL,
  codigo_referencia SMALLINT,
  razon_referencia VARCHAR(90),
  documento_emitido_origen_id INTEGER,
  orden INTEGER NOT NULL
);

COMMENT ON TABLE documento_emitido_referencias IS
  'Referencias SII por DTE emitido (NroLinRef, TpoDocRef, FolioRef, FchRef, CodRef, RazonRef).';

COMMENT ON COLUMN documento_emitido_referencias.documento_emitido_origen_id IS
  'Opcional: FK al DTE emitido en FacturaOn cuando la referencia apunta a un documento interno.';

CREATE INDEX IF NOT EXISTS idx_doc_emitido_referencias_documento
  ON documento_emitido_referencias (documento_emitido_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_doc_emitido_referencias_documento_nro_linea
  ON documento_emitido_referencias (documento_emitido_id, nro_linea);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_doc_emitido_referencias_documento'
  ) THEN
    ALTER TABLE documento_emitido_referencias
      ADD CONSTRAINT fk_doc_emitido_referencias_documento
      FOREIGN KEY (documento_emitido_id)
      REFERENCES documento_emitidos (id)
      ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_doc_emitido_referencias_tipo'
  ) THEN
    ALTER TABLE documento_emitido_referencias
      ADD CONSTRAINT fk_doc_emitido_referencias_tipo
      FOREIGN KEY (tipo_referencia_documento_id)
      REFERENCES tipo_referencia_documentos (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_doc_emitido_referencias_origen'
  ) THEN
    ALTER TABLE documento_emitido_referencias
      ADD CONSTRAINT fk_doc_emitido_referencias_origen
      FOREIGN KEY (documento_emitido_origen_id)
      REFERENCES documento_emitidos (id)
      ON DELETE SET NULL;
  END IF;
END $$;

COMMIT;
