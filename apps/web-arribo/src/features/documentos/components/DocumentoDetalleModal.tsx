import { useEffect, useId, useRef } from 'react'
import { createPortal } from 'react-dom'
import { Button } from '@/components/ui'
import type { DocumentoEmitidoDetail } from '@/features/documentos/types/documentoEmitido.types'
import {
  documentoTipoLabel,
  formatDocumentoFecha,
  formatDocumentoMonto,
} from '@/features/documentos/types/documentoEmitido.types'

interface DocumentoDetalleModalProps {
  documento: DocumentoEmitidoDetail | null
  isOpen: boolean
  isLoading: boolean
  error: string | null
  downloadingEnvioId: number | null
  downloadingPdfDocumentoId: number | null
  limpiandoEnvioId: number | null
  isFonAdmin?: boolean
  onClose: () => void
  onDownloadXml: (documento: DocumentoEmitidoDetail) => void
  onDownloadPdf: (documento: DocumentoEmitidoDetail) => void
  onLimpiarEnvio: (dteEnvioId: number) => void
}

export function DocumentoDetalleModal({
  documento,
  isOpen,
  isLoading,
  error,
  downloadingEnvioId,
  downloadingPdfDocumentoId,
  limpiandoEnvioId,
  isFonAdmin = false,
  onClose,
  onDownloadXml,
  onDownloadPdf,
  onLimpiarEnvio,
}: DocumentoDetalleModalProps) {
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

  return createPortal(
    <div className="modal-overlay" onClick={handleBackdropClick}>
      <div
        className="modal-dialog modal-dialog--form modal-dialog--documento"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId} className="modal-dialog__title">
          Detalle del documento emitido
        </h2>

        {isLoading ? (
          <p className="page-loading">Cargando detalle…</p>
        ) : error ? (
          <p className="modal-dialog__error">{error}</p>
        ) : documento ? (
          <>
            <dl className="usuario-detalle__grid">
              <div>
                <dt>Tipo</dt>
                <dd>{documentoTipoLabel(documento)}</dd>
              </div>
              <div>
                <dt>Folio</dt>
                <dd>{documento.folio}</dd>
              </div>
              <div>
                <dt>Fecha emisión</dt>
                <dd>{formatDocumentoFecha(documento.emitido_at)}</dd>
              </div>
              <div>
                <dt>Total</dt>
                <dd>{formatDocumentoMonto(documento.total)}</dd>
              </div>
              <div>
                <dt>Receptor</dt>
                <dd>
                  {documento.razon_social_receptor} ({documento.rut_receptor})
                </dd>
              </div>
              <div>
                <dt>Giro receptor</dt>
                <dd>{documento.giro_receptor}</dd>
              </div>
              <div>
                <dt>Dirección receptor</dt>
                <dd>{documento.direccion_receptor}</dd>
              </div>
              <div>
                <dt>Emitido por</dt>
                <dd>{documento.usuario_email ?? '—'}</dd>
              </div>
              <div>
                <dt>Envío DTE</dt>
                <dd>{documento.dte_envio_id ? `#${documento.dte_envio_id}` : '—'}</dd>
              </div>
            </dl>

            {documento.lineas.length > 0 ? (
              <div className="data-table-wrapper documento-detalle__lineas">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Ítem</th>
                      <th>Cant.</th>
                      <th>P. unit.</th>
                      <th>Desc. %</th>
                      <th>Subtotal</th>
                    </tr>
                  </thead>
                  <tbody>
                    {documento.lineas.map((linea, index) => (
                      <tr key={`${linea.item}-${index}`}>
                        <td>{linea.item}</td>
                        <td>{linea.cantidad}</td>
                        <td>{formatDocumentoMonto(linea.precio_unitario)}</td>
                        <td>{linea.descuento}</td>
                        <td>{formatDocumentoMonto(linea.subtotal_con_impuesto)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : null}

            <div className="modal-dialog__actions modal-dialog__actions--wrap">
              <Button
                type="button"
                variant="secondary"
                disabled={downloadingPdfDocumentoId === documento.id}
                onClick={() => onDownloadPdf(documento)}
              >
                {downloadingPdfDocumentoId === documento.id ? 'Generando PDF…' : 'Descargar PDF'}
              </Button>
              {documento.xml_disponible && documento.dte_envio_id ? (
                <Button
                  type="button"
                  variant="secondary"
                  disabled={downloadingEnvioId === documento.dte_envio_id}
                  onClick={() => onDownloadXml(documento)}
                >
                  {downloadingEnvioId === documento.dte_envio_id ? 'Descargando…' : 'Descargar XML firmado'}
                </Button>
              ) : null}
              {isFonAdmin && documento.dte_envio_id ? (
                <Button
                  type="button"
                  className="btn-danger"
                  disabled={limpiandoEnvioId === documento.dte_envio_id}
                  onClick={() => onLimpiarEnvio(documento.dte_envio_id!)}
                >
                  {limpiandoEnvioId === documento.dte_envio_id
                    ? 'Limpiando…'
                    : `Limpiar envío #${documento.dte_envio_id}`}
                </Button>
              ) : null}
              <Button ref={closeRef} type="button" variant="secondary" onClick={onClose}>
                Cerrar
              </Button>
            </div>
          </>
        ) : null}
      </div>
    </div>,
    document.body,
  )
}
