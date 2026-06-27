import { Link } from 'react-router-dom'
import { Button } from '@/components/ui'
import type { EmisionTotales } from '@/features/emision/types/emision.types'
import { formatPrecioProducto } from '@/features/productos/types/producto.types'

interface EmisionWizardStickyFooterProps {
  totales: EmisionTotales
  cantidadItems: number
  isSubmitting: boolean
  canEmit: boolean
}

export function EmisionWizardStickyFooter({
  totales,
  cantidadItems,
  isSubmitting,
  canEmit,
}: EmisionWizardStickyFooterProps) {
  return (
    <footer className="emision-wizard__sticky-footer">
      <div className="emision-wizard__sticky-footer-inner">
        <div className="emision-wizard__sticky-totales">
          <div className="emision-wizard__sticky-total-item">
            <span className="emision-wizard__sticky-label">Ítems</span>
            <strong>{cantidadItems}</strong>
          </div>
          <div className="emision-wizard__sticky-total-item">
            <span className="emision-wizard__sticky-label">Neto afecto</span>
            <strong>{formatPrecioProducto(totales.neto_afecto)}</strong>
          </div>
          <div className="emision-wizard__sticky-total-item">
            <span className="emision-wizard__sticky-label">Neto exento</span>
            <strong>{formatPrecioProducto(totales.neto_exento)}</strong>
          </div>
          {totales.neto_afecto > 0 ? (
            <div className="emision-wizard__sticky-total-item">
              <span className="emision-wizard__sticky-label">IVA ({totales.tasa_iva}%)</span>
              <strong>{formatPrecioProducto(totales.iva)}</strong>
            </div>
          ) : null}
          <div className="emision-wizard__sticky-total-item emision-wizard__sticky-total-item--total">
            <span className="emision-wizard__sticky-label">Total</span>
            <strong>{formatPrecioProducto(totales.total)}</strong>
          </div>
        </div>

        <div className="emision-wizard__sticky-actions">
          <Button type="submit" isLoading={isSubmitting} disabled={!canEmit}>
            Emitir factura
          </Button>
          <Link className="emision-checklist__link" to="/empresas">
            Cancelar
          </Link>
        </div>
      </div>
      <p className="emision-wizard__sticky-hint">
        Montos estimados según el catálogo. El total definitivo lo calcula el servidor al emitir.
      </p>
    </footer>
  )
}
