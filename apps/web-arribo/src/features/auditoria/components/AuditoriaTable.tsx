import { Button } from '@/components/ui'
import type { AuditEventSummary } from '@/features/auditoria/types/auditEvent.types'
import {
  actorLabel,
  formatAuditDateTime,
  resultadoLabel,
} from '@/features/auditoria/types/auditEvent.types'
import { useTableRowSelection } from '@/hooks/useTableRowSelection'
import {
  handleInteractiveRowKeyDown,
  interactiveRowClassName,
  stopRowClickPropagation,
} from '@/lib/interactiveTableRow'

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
  const { isSelected, select } = useTableRowSelection()

  return (
    <div className="data-table-wrapper">
      <table className="data-table data-table--interactive">
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
            <tr
              key={evento.id}
              className={interactiveRowClassName(isSelected(evento.id))}
              tabIndex={0}
              aria-selected={isSelected(evento.id)}
              onClick={() => select(evento.id)}
              onKeyDown={(event) => handleInteractiveRowKeyDown(event, () => select(evento.id))}
              onDoubleClick={() => onVerDetalle(evento)}
            >
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
              <td className="data-table__actions" onClick={stopRowClickPropagation}>
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
