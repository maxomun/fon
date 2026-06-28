import { useCallback, useEffect, useState } from 'react'
import { documentosService } from '@/features/documentos/services/documentosService'
import type {
  DocumentoEmitidoDetail,
  DocumentoEmitidoSummary,
  DocumentosListMeta,
} from '@/features/documentos/types/documentoEmitido.types'
import { ApiError } from '@/services/apiClient'

export function useDocumentosList(empresaId: number) {
  const [documentos, setDocumentos] = useState<DocumentoEmitidoSummary[]>([])
  const [meta, setMeta] = useState<DocumentosListMeta | null>(null)
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)
  const [isLoading, setIsLoading] = useState(true)
  const [listError, setListError] = useState<string | null>(null)

  const [detalleDocumento, setDetalleDocumento] = useState<DocumentoEmitidoDetail | null>(null)
  const [isDetalleOpen, setIsDetalleOpen] = useState(false)
  const [isDetalleLoading, setIsDetalleLoading] = useState(false)
  const [detalleError, setDetalleError] = useState<string | null>(null)

  const [downloadingEnvioId, setDownloadingEnvioId] = useState<number | null>(null)
  const [downloadingPdfDocumentoId, setDownloadingPdfDocumentoId] = useState<number | null>(null)
  const [downloadError, setDownloadError] = useState<string | null>(null)

  const [limpiandoEnvioId, setLimpiandoEnvioId] = useState<number | null>(null)
  const [isLimpiandoTodos, setIsLimpiandoTodos] = useState(false)
  const [limpiezaError, setLimpiezaError] = useState<string | null>(null)
  const [limpiezaMensaje, setLimpiezaMensaje] = useState<string | null>(null)

  const loadDocumentos = useCallback(async () => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      return
    }

    setListError(null)
    setIsLoading(true)

    try {
      const response = await documentosService.list(empresaId, query, page)
      setDocumentos(response.data)
      setMeta(response.meta)
    } catch (error) {
      setDocumentos([])
      setMeta(null)
      setListError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar los documentos emitidos',
      )
    } finally {
      setIsLoading(false)
    }
  }, [empresaId, query, page])

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadDocumentos()
    }, 300)

    return () => window.clearTimeout(timeout)
  }, [loadDocumentos])

  function updateQuery(value: string) {
    setPage(1)
    setQuery(value)
  }

  async function openDetalle(documento: DocumentoEmitidoSummary) {
    setDetalleDocumento(null)
    setIsDetalleOpen(true)
    setDetalleError(null)
    setIsDetalleLoading(true)

    try {
      const response = await documentosService.get(empresaId, documento.id)
      setDetalleDocumento(response.data)
    } catch (error) {
      setDetalleError(
        error instanceof ApiError ? error.message : 'No se pudo cargar el detalle del documento',
      )
    } finally {
      setIsDetalleLoading(false)
    }
  }

  function closeDetalle() {
    setIsDetalleOpen(false)
    setDetalleDocumento(null)
    setDetalleError(null)
    setIsDetalleLoading(false)
  }

  async function downloadXml(
    dteEnvioId: number,
    context?: Pick<DocumentoEmitidoSummary, 'tipo_documento' | 'folio'> & { rut_emisor?: string },
  ) {
    setDownloadError(null)
    setDownloadingEnvioId(dteEnvioId)

    try {
      await documentosService.downloadXml(empresaId, dteEnvioId, context)
    } catch (error) {
      setDownloadError(
        error instanceof ApiError ? error.message : 'No se pudo descargar el XML',
      )
    } finally {
      setDownloadingEnvioId(null)
    }
  }

  async function downloadPdf(documento: DocumentoEmitidoDetail) {
    setDownloadError(null)
    setDownloadingPdfDocumentoId(documento.id)

    try {
      await documentosService.downloadPdf(empresaId, documento.id, {
        id: documento.id,
        tipo_documento: documento.tipo_documento,
        folio: documento.folio,
        rut_emisor: documento.rut_emisor,
      })
      if (!documento.pdf_disponible) {
        setDetalleDocumento({ ...documento, pdf_disponible: true })
      }
    } catch (error) {
      setDownloadError(
        error instanceof ApiError ? error.message : 'No se pudo descargar el PDF',
      )
    } finally {
      setDownloadingPdfDocumentoId(null)
    }
  }

  async function limpiarEnvio(dteEnvioId: number) {
    setLimpiezaError(null)
    setLimpiezaMensaje(null)
    setLimpiandoEnvioId(dteEnvioId)

    try {
      const response = await documentosService.limpiarEnvio(empresaId, dteEnvioId)
      setLimpiezaMensaje(response.message ?? 'Envío eliminado y folios liberados')
      if (isDetalleOpen && detalleDocumento?.dte_envio_id === dteEnvioId) {
        closeDetalle()
      }
      await loadDocumentos()
    } catch (error) {
      setLimpiezaError(
        error instanceof ApiError ? error.message : 'No se pudo limpiar el envío',
      )
    } finally {
      setLimpiandoEnvioId(null)
    }
  }

  async function limpiarTodosEnvios() {
    setLimpiezaError(null)
    setLimpiezaMensaje(null)
    setIsLimpiandoTodos(true)

    try {
      const response = await documentosService.limpiarTodosEnvios(empresaId)
      setLimpiezaMensaje(response.message ?? 'Envíos de prueba eliminados')
      closeDetalle()
      setPage(1)
      await loadDocumentos()
    } catch (error) {
      setLimpiezaError(
        error instanceof ApiError ? error.message : 'No se pudieron limpiar los envíos',
      )
    } finally {
      setIsLimpiandoTodos(false)
    }
  }

  return {
    documentos,
    meta,
    query,
    page,
    setPage,
    updateQuery,
    isLoading,
    listError,
    detalleDocumento,
    isDetalleOpen,
    isDetalleLoading,
    detalleError,
    openDetalle,
    closeDetalle,
    downloadXml,
    downloadPdf,
    downloadingEnvioId,
    downloadingPdfDocumentoId,
    downloadError,
    limpiarEnvio,
    limpiarTodosEnvios,
    limpiandoEnvioId,
    isLimpiandoTodos,
    limpiezaError,
    limpiezaMensaje,
    reload: loadDocumentos,
  }
}
