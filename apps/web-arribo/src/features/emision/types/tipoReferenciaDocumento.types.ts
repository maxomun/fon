export interface TipoReferenciaDocumento {
  id: number
  codigo_sii: string
  nombre: string
  categoria: string
  requiere_folio: boolean
  requiere_fecha: boolean
  permite_codigo_referencia: boolean
  observacion: string | null
}

export interface TipoReferenciaDocumentosListResponse {
  success: boolean
  data: TipoReferenciaDocumento[]
}
