import { useEffect, useId, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { Button } from '@/components/ui'
import { documentosService } from '@/features/documentos/services/documentosService'
import type { DocumentoEmitidoSummary } from '@/features/documentos/types/documentoEmitido.types'
import { documentoTipoLabel } from '@/features/documentos/types/documentoEmitido.types'
import { formatXmlPreview } from '@/features/documentos/utils/formatXmlPreview'
import { ApiError } from '@/services/apiClient'

export type DocumentoArchivoPreviewKind = 'pdf' | 'xml'

export interface DocumentoArchivoPreviewTarget {
  kind: DocumentoArchivoPreviewKind
  documento: Pick<DocumentoEmitidoSummary, 'id' | 'tipo_documento' | 'tipo_documento_nombre' | 'folio'>
  dteEnvioId?: number
  rutEmisor?: string
}

interface DocumentoArchivoPreviewModalProps {
  empresaId: number
  target: DocumentoArchivoPreviewTarget | null
  onClose: () => void
}

export function DocumentoArchivoPreviewModal({
  empresaId,
  target,
  onClose,
}: DocumentoArchivoPreviewModalProps) {
  const titleId = useId()
  const closeRef = useRef<HTMLButtonElement>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [blobUrl, setBlobUrl] = useState<string | null>(null)
  const [xmlContent, setXmlContent] = useState<string | null>(null)
  const [filename, setFilename] = useState<string | null>(null)
  const [isDownloading, setIsDownloading] = useState(false)

  const isOpen = target !== null
  const kind = target?.kind ?? 'pdf'

  useEffect(() => {
    if (!isOpen || !target) {
      return
    }

    const currentTarget = target
    let cancelled = false
    let activeBlobUrl: string | null = null

    async function loadPreview() {
      setIsLoading(true)
      setError(null)
      setBlobUrl(null)
      setXmlContent(null)
      setFilename(null)

      try {
        if (currentTarget.kind === 'pdf') {
          const result = await documentosService.fetchPdfBlob(
            empresaId,
            currentTarget.documento.id,
            {
              id: currentTarget.documento.id,
              tipo_documento: currentTarget.documento.tipo_documento,
              folio: currentTarget.documento.folio,
              rut_emisor: currentTarget.rutEmisor,
            },
          )

          if (cancelled) {
            if (activeBlobUrl) {
              URL.revokeObjectURL(activeBlobUrl)
            }
            return
          }

          activeBlobUrl = URL.createObjectURL(result.blob)
          setBlobUrl(activeBlobUrl)
          setFilename(result.filename)
          return
        }

        if (!currentTarget.dteEnvioId) {
          throw new ApiError('Envío DTE no disponible', 404, 'DTE_ENVIO_NOT_FOUND')
        }

        const result = await documentosService.fetchXmlBlob(
          empresaId,
          currentTarget.dteEnvioId,
          {
            tipo_documento: currentTarget.documento.tipo_documento,
            folio: currentTarget.documento.folio,
            rut_emisor: currentTarget.rutEmisor,
          },
        )

        if (cancelled) {
          return
        }

        setXmlContent(await formatXmlPreview(result.blob))
        setFilename(result.filename)
      } catch (loadError) {
        if (!cancelled) {
          setError(
            loadError instanceof ApiError
              ? loadError.message
              : 'No se pudo cargar la vista previa',
          )
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false)
        }
      }
    }

    void loadPreview()

    return () => {
      cancelled = true
      if (activeBlobUrl) {
        URL.revokeObjectURL(activeBlobUrl)
      }
    }
  }, [empresaId, isOpen, target])

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

  if (!isOpen || !target) {
    return null
  }

  const title =
    kind === 'pdf'
      ? `PDF — ${documentoTipoLabel(target.documento)} folio ${target.documento.folio}`
      : `XML firmado — envío #${target.dteEnvioId ?? '—'}`

  async function handleDownload() {
    if (!target) {
      return
    }

    setIsDownloading(true)

    try {
      if (target.kind === 'pdf') {
        await documentosService.downloadPdf(empresaId, target.documento.id, {
          id: target.documento.id,
          tipo_documento: target.documento.tipo_documento,
          folio: target.documento.folio,
          rut_emisor: target.rutEmisor,
        })
      } else if (target.dteEnvioId) {
        await documentosService.downloadXml(empresaId, target.dteEnvioId, {
          tipo_documento: target.documento.tipo_documento,
          folio: target.documento.folio,
          rut_emisor: target.rutEmisor,
        })
      }
    } catch (downloadError) {
      setError(
        downloadError instanceof ApiError
          ? downloadError.message
          : 'No se pudo descargar el archivo',
      )
    } finally {
      setIsDownloading(false)
    }
  }

  function handleBackdropClick() {
    if (!isLoading) {
      onClose()
    }
  }

  return createPortal(
    <div className="modal-overlay modal-overlay--preview" onClick={handleBackdropClick}>
      <div
        className="modal-dialog modal-dialog--preview"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId} className="modal-dialog__title">
          {title}
        </h2>

        {isLoading ? <p className="page-loading">Cargando vista previa…</p> : null}
        {error ? <p className="modal-dialog__error">{error}</p> : null}

        {!isLoading && !error && kind === 'pdf' && blobUrl ? (
          <iframe
            className="documento-preview__iframe"
            src={blobUrl}
            title={filename ?? 'Vista previa PDF'}
          />
        ) : null}

        {!isLoading && !error && kind === 'xml' && xmlContent ? (
          <pre className="documento-preview__xml">{xmlContent}</pre>
        ) : null}

        <div className="modal-dialog__actions modal-dialog__actions--wrap">
          <Button
            type="button"
            variant="secondary"
            disabled={isLoading || !!error || isDownloading}
            onClick={() => void handleDownload()}
          >
            {isDownloading ? 'Descargando…' : 'Descargar'}
          </Button>
          <Button ref={closeRef} type="button" variant="secondary" onClick={onClose}>
            Cerrar
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
