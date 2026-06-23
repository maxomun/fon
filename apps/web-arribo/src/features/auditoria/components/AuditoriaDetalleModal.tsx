import { useEffect, useId, useRef } from 'react'
import { createPortal } from 'react-dom'
import { Button } from '@/components/ui'
import type { AuditEventDetail } from '@/features/auditoria/types/auditEvent.types'
import {
  actorLabel,
  categoriaLabel,
  formatAuditDateTime,
  formatCambioValor,
  resultadoLabel,
} from '@/features/auditoria/types/auditEvent.types'

interface AuditoriaDetalleModalProps {
  evento: AuditEventDetail | null
  isOpen: boolean
  isLoading: boolean
  error: string | null
  onClose: () => void
}

export function AuditoriaDetalleModal({
  evento,
  isOpen,
  isLoading,
  error,
  onClose,
}: AuditoriaDetalleModalProps) {
  const closeRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()

  useEffect(() => {
    if (!isOpen) {
      return
    }

    closeRef.current?.focus()

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape' && !isLoading) {
        onClose()
      }
    }

    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [isOpen, isLoading, onClose])

  if (!isOpen) {
    return null
  }

  function handleBackdropClick() {
    if (!isLoading) {
      onClose()
    }
  }

  const cambios = evento ? Object.entries(evento.cambios ?? {}) : []
  const metadata = evento ? Object.entries(evento.metadata ?? {}) : []

  return createPortal(
    <div className="modal-overlay" onClick={handleBackdropClick}>
      <div
        className="modal-dialog modal-dialog--form"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId} className="modal-dialog__title">
          {evento?.accion_label ?? 'Detalle de auditoría'}
        </h2>

        {isLoading ? (
          <p className="page-loading">Cargando detalle…</p>
        ) : error ? (
          <p className="modal-dialog__error">{error}</p>
        ) : evento ? (
          <div className="usuario-detalle">
            <dl className="usuario-detalle__grid">
              <div>
                <dt>Fecha</dt>
                <dd>{formatAuditDateTime(evento.created_at)}</dd>
              </div>
              <div>
                <dt>Categoría</dt>
                <dd>{categoriaLabel(evento.categoria)}</dd>
              </div>
              <div>
                <dt>Resultado</dt>
                <dd>
                  <span
                    className={`badge ${
                      evento.resultado === 'success' ? 'badge--success' : 'badge--warning'
                    }`}
                  >
                    {resultadoLabel(evento.resultado)}
                  </span>
                </dd>
              </div>
              <div>
                <dt>Actor</dt>
                <dd>
                  {actorLabel(evento.actor)}
                  {evento.actor.email ? ` (${evento.actor.email})` : ''}
                </dd>
              </div>
              {evento.empresa ? (
                <div>
                  <dt>Empresa</dt>
                  <dd>{evento.empresa.razon_social ?? `ID ${evento.empresa.id}`}</dd>
                </div>
              ) : null}
              {evento.recurso?.label ? (
                <div>
                  <dt>Recurso</dt>
                  <dd>{evento.recurso.label}</dd>
                </div>
              ) : null}
              {evento.mensaje ? (
                <div>
                  <dt>Mensaje</dt>
                  <dd>{evento.mensaje}</dd>
                </div>
              ) : null}
              {evento.codigo_error ? (
                <div>
                  <dt>Código error</dt>
                  <dd>{evento.codigo_error}</dd>
                </div>
              ) : null}
            </dl>

            {cambios.length > 0 ? (
              <>
                <h3 className="usuario-detalle__subtitle">Cambios</h3>
                <ul className="auditoria-detalle__lista">
                  {cambios.map(([campo, valor]) => (
                    <li key={campo}>
                      <strong>{campo}</strong>
                      {Array.isArray(valor) && valor.length === 2 ? (
                        <span>
                          {formatCambioValor(valor[0])} → {formatCambioValor(valor[1])}
                        </span>
                      ) : (
                        <span>{formatCambioValor(valor)}</span>
                      )}
                    </li>
                  ))}
                </ul>
              </>
            ) : null}

            {metadata.length > 0 ? (
              <>
                <h3 className="usuario-detalle__subtitle">Metadata</h3>
                <ul className="auditoria-detalle__lista">
                  {metadata.map(([campo, valor]) => (
                    <li key={campo}>
                      <strong>{campo}</strong>
                      <span>{formatCambioValor(valor)}</span>
                    </li>
                  ))}
                </ul>
              </>
            ) : null}

            {evento.ip || evento.request_id ? (
              <>
                <h3 className="usuario-detalle__subtitle">Contexto técnico</h3>
                <dl className="usuario-detalle__grid">
                  {evento.ip ? (
                    <div>
                      <dt>IP</dt>
                      <dd>{evento.ip}</dd>
                    </div>
                  ) : null}
                  {evento.request_id ? (
                    <div>
                      <dt>Request ID</dt>
                      <dd>{evento.request_id}</dd>
                    </div>
                  ) : null}
                  {evento.user_agent ? (
                    <div>
                      <dt>User agent</dt>
                      <dd className="auditoria-detalle__user-agent">{evento.user_agent}</dd>
                    </div>
                  ) : null}
                </dl>
              </>
            ) : null}
          </div>
        ) : null}

        <div className="modal-dialog__actions">
          <Button ref={closeRef} type="button" onClick={onClose} disabled={isLoading}>
            Cerrar
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
