export interface DocumentoEmitidoSummary {
  id: number
  folio: number
  tipo_documento: string
  tipo_documento_nombre: string
  rut_receptor: string
  razon_social_receptor: string
  total: string
  dte_envio_id: number | null
  xml_disponible: boolean
  pdf_disponible: boolean
  emitido_at: string | null
  usuario_email: string | null
}

export interface DocumentoEmitidoLinea {
  item: string
  cantidad: number
  precio_unitario: string
  descuento: number
  afecto: boolean
  impuesto: number
  subtotal_con_impuesto: string
}

export interface DocumentoEmitidoReferencia {
  nro_linea: number
  orden: number
  tipo_documento_referencia: string
  tipo_documento_referencia_nombre: string
  folio_referencia: string
  fecha_referencia: string
  codigo_referencia: number | null
  razon_referencia: string | null
  documento_emitido_origen_id: number | null
}

export interface DocumentoReferenciaUso {
  documento_emitido_id: number
  folio: number
  tipo_documento: string
  tipo_documento_nombre: string
}

export interface DocumentoParaReferencia {
  id: number
  folio: number
  tipo_documento: string
  tipo_documento_nombre: string
  fecha_emision: string | null
  rut_receptor: string
  razon_social_receptor: string
  total: string
  referenciado_en: DocumentoReferenciaUso[]
}

export interface DocumentosParaReferenciaResponse {
  success?: boolean
  data: DocumentoParaReferencia[]
}

export interface DocumentoEmitidoDetail extends DocumentoEmitidoSummary {
  rut_emisor: string
  razon_social_emisor: string
  giro_receptor: string
  direccion_receptor: string
  fecha_emision: string | null
  lineas: DocumentoEmitidoLinea[]
  referencias: DocumentoEmitidoReferencia[]
}

export interface DocumentosListMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

export interface DocumentosListResponse {
  success?: boolean
  data: DocumentoEmitidoSummary[]
  meta: DocumentosListMeta
}

export interface DocumentoDetailResponse {
  success?: boolean
  data: DocumentoEmitidoDetail
}

export interface LimpiarEnvioData {
  dte_envio_id: number
  documentos_eliminados: number
  folios_liberados: number[]
  documento_ids: number[]
}

export interface LimpiarEnvioResponse {
  success?: boolean
  message?: string
  data: LimpiarEnvioData
}

export interface LimpiarTodosEnviosData {
  success: boolean
  envios_limpiados: number
  documentos_eliminados: number
  folios_liberados: number[]
  errores: Array<{ dte_envio_id: number; error: string; code?: string }>
}

export interface LimpiarTodosEnviosResponse {
  success?: boolean
  message?: string
  data: LimpiarTodosEnviosData
}

export function formatDocumentoFecha(iso: string | null) {
  if (!iso) {
    return '—'
  }

  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) {
    return '—'
  }

  return date.toLocaleString('es-CL', {
    dateStyle: 'short',
    timeStyle: 'short',
  })
}

export function formatDocumentoFechaSolo(fecha: string | null) {
  if (!fecha) {
    return '—'
  }

  const date = new Date(`${fecha}T12:00:00`)
  if (Number.isNaN(date.getTime())) {
    return fecha
  }

  return date.toLocaleDateString('es-CL')
}

export function referenciaTipoLabel(
  referencia: Pick<DocumentoEmitidoReferencia, 'tipo_documento_referencia' | 'tipo_documento_referencia_nombre'>,
) {
  return `${referencia.tipo_documento_referencia} — ${referencia.tipo_documento_referencia_nombre}`
}

export function documentoPuedeReferenciarseEnEmision(tipoDocumento: string) {
  return ['33', '34', '39', '41', '46', '52', '56', '61', '110', '111', '112'].includes(tipoDocumento)
}

export function buildReferenciaDesdeDocumentoEmitido(
  documento: Pick<
    DocumentoEmitidoDetail,
    'id' | 'tipo_documento' | 'folio' | 'fecha_emision' | 'emitido_at'
  >,
) {
  const fecha =
    documento.fecha_emision?.slice(0, 10) ||
    (documento.emitido_at ? documento.emitido_at.slice(0, 10) : '')

  return {
    documento_emitido_origen_id: documento.id,
    tipo_documento_referencia: documento.tipo_documento,
    folio_referencia: String(documento.folio),
    fecha_referencia: fecha,
  }
}

export function formatDocumentoMonto(valor: string) {
  const numero = Number(valor)
  if (!Number.isFinite(numero)) {
    return valor
  }

  return numero.toLocaleString('es-CL', {
    style: 'currency',
    currency: 'CLP',
    maximumFractionDigits: 0,
  })
}

export function documentoTipoLabel(documento: Pick<DocumentoEmitidoSummary, 'tipo_documento' | 'tipo_documento_nombre'>) {
  return `${documento.tipo_documento} — ${documento.tipo_documento_nombre}`
}

export function buildPdfDownloadFilename(
  documento: Pick<DocumentoEmitidoSummary, 'tipo_documento' | 'folio' | 'id'>,
  rutEmisor?: string,
) {
  const rut = (rutEmisor ?? 'emisor').replace(/[.\s]/g, '')
  const fecha = new Date().toISOString().slice(0, 10).replace(/-/g, '')
  return `dte_${documento.tipo_documento}_folio_${documento.folio}_${rut}_${fecha}.pdf`
}

export function buildXmlDownloadFilename(
  dteEnvioId: number,
  documento: Pick<DocumentoEmitidoSummary, 'tipo_documento' | 'folio'>,
  rutEmisor?: string,
) {
  const rut = (rutEmisor ?? 'emisor').replace(/[.\s]/g, '')
  const fecha = new Date().toISOString().slice(0, 10).replace(/-/g, '')
  return `envio_${dteEnvioId}_dte_${documento.tipo_documento}_folio_${documento.folio}_${rut}_${fecha}.xml`
}
