import { useMemo } from 'react'
import type { DocumentoEmitidoSummary } from '@/features/documentos/types/documentoEmitido.types'
import {
  documentoTipoLabel,
  formatDocumentoFecha,
  formatDocumentoMonto,
} from '@/features/documentos/types/documentoEmitido.types'
import { Button } from '@/components/ui'

interface DocumentosTableProps {
  documentos: DocumentoEmitidoSummary[]
  downloadingEnvioId: number | null
  limpiandoEnvioId: number | null
  isFonAdmin?: boolean
  onVerDetalle: (documento: DocumentoEmitidoSummary) => void
  onDownloadXml: (documento: DocumentoEmitidoSummary) => void
  onLimpiarEnvio: (dteEnvioId: number) => void
}

export function DocumentosTable({
  documentos,
  downloadingEnvioId,
  limpiandoEnvioId,
  isFonAdmin = false,
  onVerDetalle,
  onDownloadXml,
  onLimpiarEnvio,
}: DocumentosTableProps) {
  const primerDocumentoPorEnvio = useMemo(() => {
    const map = new Map<number, number>()

    for (const documento of documentos) {
      if (documento.dte_envio_id && !map.has(documento.dte_envio_id)) {
        map.set(documento.dte_envio_id, documento.id)
      }
    }

    return map
  }, [documentos])
  return (
    <div className="data-table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            <th>Fecha</th>
            <th>Folio</th>
            <th>Tipo</th>
            <th>Receptor</th>
            <th>Total</th>
            <th>XML</th>
            <th aria-label="Acciones" />
          </tr>
        </thead>
        <tbody>
          {documentos.map((documento) => {
            const puedeLimpiarEnvio =
              isFonAdmin &&
              documento.dte_envio_id &&
              primerDocumentoPorEnvio.get(documento.dte_envio_id) === documento.id

            return (
            <tr key={documento.id}>
              <td>{formatDocumentoFecha(documento.emitido_at)}</td>
              <td>{documento.folio}</td>
              <td>{documentoTipoLabel(documento)}</td>
              <td>
                <div className="documentos-table__receptor">
                  <span>{documento.razon_social_receptor}</span>
                  <span className="documentos-table__receptor-rut">{documento.rut_receptor}</span>
                </div>
              </td>
              <td>{formatDocumentoMonto(documento.total)}</td>
              <td>
                {documento.xml_disponible && documento.dte_envio_id ? (
                  <span className="badge badge--success">Disponible</span>
                ) : (
                  <span className="badge badge--warning">Sin archivo</span>
                )}
              </td>
              <td className="data-table__actions">
                <div className="documentos-table__actions">
                  <Button type="button" variant="secondary" onClick={() => onVerDetalle(documento)}>
                    Ver detalle
                  </Button>
                  {documento.xml_disponible && documento.dte_envio_id ? (
                    <Button
                      type="button"
                      variant="secondary"
                      disabled={downloadingEnvioId === documento.dte_envio_id}
                      onClick={() => onDownloadXml(documento)}
                    >
                      {downloadingEnvioId === documento.dte_envio_id ? 'Descargando…' : 'Descargar XML'}
                    </Button>
                  ) : null}
                  {puedeLimpiarEnvio ? (
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
                </div>
              </td>
            </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
