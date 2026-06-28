import { Download, Eye, FileCode, FileText, Trash2 } from 'lucide-react'
import { IconButton } from '@/components/ui/IconButton'
import type { DocumentoEmitidoSummary } from '@/features/documentos/types/documentoEmitido.types'

interface DocumentoRowActionsProps {
  documento: DocumentoEmitidoSummary
  downloadingEnvioId: number | null
  downloadingPdfDocumentoId: number | null
  limpiandoEnvioId: number | null
  puedeLimpiarEnvio: boolean
  onVerDetalle: (documento: DocumentoEmitidoSummary) => void
  onPreviewPdf: (documento: DocumentoEmitidoSummary) => void
  onPreviewXml: (documento: DocumentoEmitidoSummary) => void
  onDownloadXml: (documento: DocumentoEmitidoSummary) => void
  onLimpiarEnvio: (dteEnvioId: number) => void
}

export function DocumentoRowActions({
  documento,
  downloadingEnvioId,
  downloadingPdfDocumentoId,
  limpiandoEnvioId,
  puedeLimpiarEnvio,
  onVerDetalle,
  onPreviewPdf,
  onPreviewXml,
  onDownloadXml,
  onLimpiarEnvio,
}: DocumentoRowActionsProps) {
  const xmlDisponible = documento.xml_disponible && documento.dte_envio_id != null
  const descargandoXml =
    xmlDisponible && downloadingEnvioId === documento.dte_envio_id
  const generandoPdf = downloadingPdfDocumentoId === documento.id
  const limpiando =
    puedeLimpiarEnvio &&
    documento.dte_envio_id != null &&
    limpiandoEnvioId === documento.dte_envio_id

  return (
    <div className="table-actions table-actions--icons">
      <IconButton
        icon={Eye}
        label="Ver detalle del documento"
        onClick={() => onVerDetalle(documento)}
      />
      <IconButton
        icon={FileText}
        label="Ver PDF tributario"
        isLoading={generandoPdf}
        onClick={() => onPreviewPdf(documento)}
      />
      <IconButton
        icon={FileCode}
        label={xmlDisponible ? 'Ver XML firmado' : 'XML no disponible'}
        disabled={!xmlDisponible}
        onClick={() => onPreviewXml(documento)}
      />
      <IconButton
        icon={Download}
        label={xmlDisponible ? 'Descargar XML firmado' : 'XML no disponible'}
        disabled={!xmlDisponible}
        isLoading={descargandoXml}
        onClick={() => onDownloadXml(documento)}
      />
      {puedeLimpiarEnvio && documento.dte_envio_id ? (
        <IconButton
          icon={Trash2}
          label={`Limpiar envío #${documento.dte_envio_id}`}
          variant="danger"
          isLoading={limpiando}
          onClick={() => onLimpiarEnvio(documento.dte_envio_id!)}
        />
      ) : null}
    </div>
  )
}
