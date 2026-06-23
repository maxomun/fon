import { Button } from '@/components/ui'
import type { AuditEventSummary } from '@/features/auditoria/types/auditEvent.types'
import {
  actorLabel,
  formatAuditDateTime,
  resultadoLabel,
} from '@/features/auditoria/types/auditEvent.types'

interface AuditoriaTableProps {
  eventos: AuditEventSummary[]
  showEmpresaColumn?: boolean
  onVerDetalle: (evento: AuditEventSummary) => void
}

export function AuditoriaTable({
  eventos,
  showEmpresaColumn = false,
  onVerDetalle,
}: AuditoriaTableProps) {
  return (
    <div className="data-table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            <th>Fecha</th>
            <th>Actor</th>
            <th>Acción</th>
            <th>Recurso</th>
            {showEmpresaColumn ? <th>Empresa</th> : null}
            <th>Resultado</th>
            <th aria-label="Acciones" />
          </tr>
        </thead>
        <tbody>
          {eventos.map((evento) => (
            <tr key={evento.id}>
              <td>{formatAuditDateTime(evento.created_at)}</td>
              <td>
                <div className="auditoria-table__actor">
                  <span>{actorLabel(evento.actor)}</span>
                  {evento.actor.acceso_global ? (
                    <span className="badge badge--info">FON</span>
                  ) : null}
                </div>
              </td>
              <td>
                <div className="auditoria-table__accion">
                  <strong>{evento.accion_label}</strong>
                  <span className="auditoria-table__accion-codigo">{evento.accion}</span>
                </div>
              </td>
              <td>{evento.recurso?.label ?? '—'}</td>
              {showEmpresaColumn ? (
                <td>{evento.empresa?.razon_social ?? '—'}</td>
              ) : null}
              <td>
                <span
                  className={`badge ${
                    evento.resultado === 'success' ? 'badge--success' : 'badge--warning'
                  }`}
                >
                  {resultadoLabel(evento.resultado)}
                </span>
              </td>
              <td className="data-table__actions">
                <Button type="button" variant="secondary" onClick={() => onVerDetalle(evento)}>
                  Ver detalle
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
