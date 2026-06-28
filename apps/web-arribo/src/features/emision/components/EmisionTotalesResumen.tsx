import type { EmisionTotales } from '@/features/emision/types/emision.types'
import { formatPrecioProducto } from '@/features/productos/types/producto.types'

interface EmisionTotalesResumenProps {
  totales: EmisionTotales
  cantidadItems: number
}

export function EmisionTotalesResumen({ totales, cantidadItems }: EmisionTotalesResumenProps) {
  return (
    <div className="emision-wizard__totales">
      <h3>Resumen</h3>
      <dl className="emision-wizard__totales-grid">
        <div>
          <dt>Ítems</dt>
          <dd>{cantidadItems}</dd>
        </div>
        <div>
          <dt>Neto afecto</dt>
          <dd>{formatPrecioProducto(totales.neto_afecto)}</dd>
        </div>
        <div>
          <dt>Neto exento</dt>
          <dd>{formatPrecioProducto(totales.neto_exento)}</dd>
        </div>
        {totales.neto_no_facturable > 0 ? (
          <div>
            <dt>No facturable</dt>
            <dd>{formatPrecioProducto(totales.neto_no_facturable)}</dd>
          </div>
        ) : null}
        {totales.neto_afecto > 0 ? (
          <div>
            <dt>IVA ({totales.tasa_iva}%)</dt>
            <dd>{formatPrecioProducto(totales.iva)}</dd>
          </div>
        ) : null}
        <div className="emision-wizard__totales-total">
          <dt>Total</dt>
          <dd>{formatPrecioProducto(totales.total)}</dd>
        </div>
      </dl>
      <p className="emision-wizard__hint">
        Montos estimados según precios y tasas vigentes del catálogo. El total definitivo lo
        calcula el servidor al emitir.
      </p>
    </div>
  )
}
