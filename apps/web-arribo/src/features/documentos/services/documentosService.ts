import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  DocumentoDetailResponse,
  DocumentoEmitidoSummary,
  DocumentosListResponse,
  LimpiarEnvioResponse,
  LimpiarTodosEnviosResponse,
} from '@/features/documentos/types/documentoEmitido.types'
import { buildPdfDownloadFilename, buildXmlDownloadFilename } from '@/features/documentos/types/documentoEmitido.types'

function baseUrl(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/documentos_emitidos`
}

function listQuery(query = '', page = 1, tipoDocumento?: string) {
  const params = new URLSearchParams()
  params.set('page', String(page))
  params.set('per_page', '25')

  if (query.trim()) {
    params.set('q', query.trim())
  }

  if (tipoDocumento?.trim()) {
    params.set('tipo_documento', tipoDocumento.trim())
  }

  return `?${params.toString()}`
}

function triggerDownload(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  anchor.click()
  URL.revokeObjectURL(url)
}

function dteEnviosBaseUrl(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/dte_envios`
}

export const documentosService = {
  list(empresaId: number, query = '', page = 1, tipoDocumento?: string) {
    return authenticatedClient.get<DocumentosListResponse>(
      `${baseUrl(empresaId)}${listQuery(query, page, tipoDocumento)}`,
    )
  },

  get(empresaId: number, documentoId: number) {
    return authenticatedClient.get<DocumentoDetailResponse>(`${baseUrl(empresaId)}/${documentoId}`)
  },

  async downloadXml(
    empresaId: number,
    dteEnvioId: number,
    context?: Pick<DocumentoEmitidoSummary, 'tipo_documento' | 'folio'> & { rut_emisor?: string },
  ) {
    const fallbackFilename = context
      ? buildXmlDownloadFilename(dteEnvioId, context, context.rut_emisor)
      : undefined

    const { blob, filename } = await authenticatedClient.download(
      `${dteEnviosBaseUrl(empresaId)}/${dteEnvioId}/xml`,
      { fallbackFilename },
    )
    triggerDownload(blob, filename)
  },

  async downloadPdf(
    empresaId: number,
    documentoId: number,
    context?: Pick<DocumentoEmitidoSummary, 'tipo_documento' | 'folio' | 'id'> & {
      rut_emisor?: string
    },
  ) {
    const fallbackFilename = context
      ? buildPdfDownloadFilename(context, context.rut_emisor)
      : undefined

    const { blob, filename } = await authenticatedClient.download(
      `${baseUrl(empresaId)}/${documentoId}/pdf`,
      { fallbackFilename },
    )
    triggerDownload(blob, filename)
  },

  limpiarEnvio(empresaId: number, dteEnvioId: number) {
    return authenticatedClient.delete<LimpiarEnvioResponse>(
      `${dteEnviosBaseUrl(empresaId)}/${dteEnvioId}/limpiar`,
    )
  },

  limpiarTodosEnvios(empresaId: number) {
    return authenticatedClient.delete<LimpiarTodosEnviosResponse>(
      `${dteEnviosBaseUrl(empresaId)}/limpiar_todos`,
    )
  },
}
