-- Clasificación de monto por producto y línea de venta (F2 descuentos/recargos).
-- Ejecutar manualmente si la BD aún no tiene estas columnas.
--
-- Ejemplo (local):
--   docker compose exec -T postgres psql -U fon -d fon_dev -f - < apps/db/manual/productos_ambito_monto.sql

BEGIN;

ALTER TABLE productos
  ADD COLUMN IF NOT EXISTS ambito_monto VARCHAR(30) NULL;

COMMENT ON COLUMN productos.ambito_monto IS
  'AFECTO | EXENTO_NO_AFECTO | NO_FACTURABLE. NULL = derivar de impuestos del producto.';

ALTER TABLE venta_detalles
  ADD COLUMN IF NOT EXISTS ambito_monto VARCHAR(30) NULL;

UPDATE venta_detalles
SET ambito_monto = CASE WHEN afecto THEN 'AFECTO' ELSE 'EXENTO_NO_AFECTO' END
WHERE ambito_monto IS NULL;

COMMENT ON COLUMN venta_detalles.ambito_monto IS
  'Clasificación SII del ítem al momento de la emisión.';

COMMIT;
