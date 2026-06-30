-- Catálogo de tipos de documento referenciables en <Referencia> (SII).
-- No confundir con tipo_documentos (tipos DTE emitibles por la empresa).
--
-- Ejecutar ANTES de documento_emitido_referencias.sql
--
-- Ejemplo (local):
--   psql -h localhost -U fon -d fon23_dev -f apps/db/manual/tipo_referencia_documentos.sql

BEGIN;

CREATE TABLE IF NOT EXISTS tipo_referencia_documentos (
  id SERIAL PRIMARY KEY,
  codigo_sii VARCHAR(10) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  categoria VARCHAR(30) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  requiere_folio BOOLEAN NOT NULL DEFAULT TRUE,
  requiere_fecha BOOLEAN NOT NULL DEFAULT TRUE,
  permite_codigo_referencia BOOLEAN NOT NULL DEFAULT FALSE,
  observacion VARCHAR(250)
);

COMMENT ON TABLE tipo_referencia_documentos IS
  'Catálogo SII de TpoDocRef para nodos <Referencia> en DTE (emisión y futuras NC/ND).';

COMMENT ON COLUMN tipo_referencia_documentos.categoria IS
  'DTE | DOCUMENTO_COMERCIAL | DOCUMENTO_INTERNO | OTRO';

CREATE UNIQUE INDEX IF NOT EXISTS uq_tipo_referencia_documentos_codigo
  ON tipo_referencia_documentos (codigo_sii);

-- Semilla inicial (idempotente por codigo_sii)
INSERT INTO tipo_referencia_documentos
  (codigo_sii, nombre, categoria, permite_codigo_referencia, observacion)
VALUES
  ('33', 'Factura Electrónica', 'DTE', FALSE, NULL),
  ('34', 'Factura No Afecta o Exenta Electrónica', 'DTE', FALSE, NULL),
  ('39', 'Boleta Electrónica', 'DTE', FALSE, NULL),
  ('41', 'Boleta No Afecta o Exenta Electrónica', 'DTE', FALSE, NULL),
  ('46', 'Factura de Compra Electrónica', 'DTE', FALSE, NULL),
  ('52', 'Guía de Despacho Electrónica', 'DTE', FALSE, 'Uso típico: facturar guía'),
  ('56', 'Nota de Débito Electrónica', 'DTE', TRUE, 'CodRef obligatorio en NC/ND'),
  ('61', 'Nota de Crédito Electrónica', 'DTE', TRUE, 'CodRef obligatorio en NC/ND'),
  ('110', 'Factura de Exportación Electrónica', 'DTE', FALSE, NULL),
  ('111', 'Nota de Débito de Exportación Electrónica', 'DTE', TRUE, NULL),
  ('112', 'Nota de Crédito de Exportación Electrónica', 'DTE', TRUE, NULL),
  ('801', 'Orden de Compra', 'DOCUMENTO_COMERCIAL', FALSE, 'Documento comercial del receptor'),
  ('802', 'Recepción de Mercadería / Servicio', 'DOCUMENTO_COMERCIAL', FALSE, 'HES / MIGO / recepción conforme'),
  ('50', 'Guía de Despacho (manual)', 'DOCUMENTO_INTERNO', FALSE, 'Solo referencia en XML'),
  ('30', 'Factura (manual)', 'DOCUMENTO_INTERNO', FALSE, NULL),
  ('35', 'Boleta (manual)', 'DOCUMENTO_INTERNO', FALSE, NULL),
  ('60', 'Nota de Crédito (manual)', 'DOCUMENTO_INTERNO', TRUE, NULL),
  ('55', 'Nota de Débito (manual)', 'DOCUMENTO_INTERNO', TRUE, NULL)
ON CONFLICT (codigo_sii) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  categoria = EXCLUDED.categoria,
  permite_codigo_referencia = EXCLUDED.permite_codigo_referencia,
  observacion = EXCLUDED.observacion,
  activo = EXCLUDED.activo;

COMMIT;
