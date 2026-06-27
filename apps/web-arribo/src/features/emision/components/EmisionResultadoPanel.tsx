import { Link } from 'react-router-dom'
import { Alert, Button } from '@/components/ui'
import type { EmisionGenerarResponse } from '@/features/emision/types/emision.types'

interface EmisionResultadoPanelProps {
  empresaId: number
  resultado: EmisionGenerarResponse
  onEmitirOtro: () => void
}

export function EmisionResultadoPanel({
  empresaId,
  resultado,
  onEmitirOtro,
}: EmisionResultadoPanelProps) {
  const folios = resultado.data?.folios_usados ?? []
  const documentos = resultado.data?.documentos_emitidos ?? []

  return (
    <section className="panel-card emision-wizard__resultado">
      <Alert variant="success">{resultado.message ?? 'Documento emitido correctamente.'}</Alert>

      {folios.length > 0 ? (
        <p className="emision-wizard__resultado-folios">
          Folio{folios.length === 1 ? '' : 's'} timbrado{folios.length === 1 ? '' : 's'}:{' '}
          <strong>{folios.join(', ')}</strong>
          {resultado.data?.dte_envio_id ? (
            <span className="emision-wizard__resultado-archivo">
              {' '}
              · XML archivado (envío #{resultado.data.dte_envio_id})
            </span>
          ) : null}
        </p>
      ) : null}

      {documentos.length > 0 ? (
        <ul className="emision-wizard__resultado-list">
          {documentos.map((documento) => (
            <li key={documento.id}>
              DTE {documento.tipo_documento} folio {documento.folio} —{' '}
              {documento.razon_social_receptor} ({documento.rut_receptor})
            </li>
          ))}
        </ul>
      ) : null}

      <div className="emision-wizard__actions">
        <Button type="button" variant="secondary" onClick={onEmitirOtro}>
          Emitir otro documento
        </Button>
        <Link className="emision-checklist__link" to={`/empresas/${empresaId}/documentos`}>
          Ver documentos emitidos
        </Link>
        <Link className="emision-checklist__link" to={`/empresas/${empresaId}/emitir`}>
          Volver a requisitos
        </Link>
      </div>
    </section>
  )
}
