import { useMemo } from 'react'
import type { DocumentoEmitidoSummary } from '@/features/documentos/types/documentoEmitido.types'
import {
  formatDocumentoFecha,
  formatDocumentoMonto,
} from '@/features/documentos/types/documentoEmitido.types'
import { DocumentoRowActions } from '@/features/documentos/components/DocumentoRowActions'
import { useTableRowSelection } from '@/hooks/useTableRowSelection'
import {
  handleInteractiveRowKeyDown,
  interactiveRowClassName,
  stopRowClickPropagation,
} from '@/lib/interactiveTableRow'

interface DocumentosTableProps {
  documentos: DocumentoEmitidoSummary[]
  downloadingEnvioId: number | null
  downloadingPdfDocumentoId: number | null
  limpiandoEnvioId: number | null
  isFonAdmin?: boolean
  onVerDetalle: (documento: DocumentoEmitidoSummary) => void
  onPreviewPdf: (documento: DocumentoEmitidoSummary) => void
  onDownloadXml: (documento: DocumentoEmitidoSummary) => void
  onPreviewXml: (documento: DocumentoEmitidoSummary) => void
  onLimpiarEnvio: (dteEnvioId: number) => void
}

export function DocumentosTable({
  documentos,
  downloadingEnvioId,
  downloadingPdfDocumentoId,
  limpiandoEnvioId,
  isFonAdmin = false,
  onVerDetalle,
  onPreviewPdf,
  onDownloadXml,
  onPreviewXml,
  onLimpiarEnvio,
}: DocumentosTableProps) {
  const { isSelected, select } = useTableRowSelection()
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
      <table className="data-table data-table--compact data-table--interactive">
        <thead>
          <tr>
            <th>Fecha</th>
            <th>Folio</th>
            <th>Tipo</th>
            <th>Receptor</th>
            <th>Total</th>
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
              <tr
                key={documento.id}
                className={interactiveRowClassName(isSelected(documento.id))}
                tabIndex={0}
                aria-selected={isSelected(documento.id)}
                onClick={() => select(documento.id)}
                onKeyDown={(event) =>
                  handleInteractiveRowKeyDown(event, () => select(documento.id))
                }
                onDoubleClick={() => onVerDetalle(documento)}
              >
                <td className="documentos-table__fecha">{formatDocumentoFecha(documento.emitido_at)}</td>
                <td>{documento.folio}</td>
                <td>
                  <span
                    className="documentos-table__tipo"
                    title={`${documento.tipo_documento} — ${documento.tipo_documento_nombre}`}
                  >
                    {documento.tipo_documento}
                  </span>
                </td>
                <td>
                  <span
                    className="documentos-table__receptor-inline"
                    title={`${documento.razon_social_receptor} (${documento.rut_receptor})`}
                  >
                    {documento.razon_social_receptor}
                    <span className="documentos-table__receptor-sep"> · </span>
                    {documento.rut_receptor}
                  </span>
                </td>
                <td>{formatDocumentoMonto(documento.total)}</td>
                <td className="data-table__actions" onClick={stopRowClickPropagation}>
                  <DocumentoRowActions
                    documento={documento}
                    downloadingEnvioId={downloadingEnvioId}
                    downloadingPdfDocumentoId={downloadingPdfDocumentoId}
                    limpiandoEnvioId={limpiandoEnvioId}
                    puedeLimpiarEnvio={Boolean(puedeLimpiarEnvio)}
                    onVerDetalle={onVerDetalle}
                    onPreviewPdf={onPreviewPdf}
                    onPreviewXml={onPreviewXml}
                    onDownloadXml={onDownloadXml}
                    onLimpiarEnvio={onLimpiarEnvio}
                  />
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
