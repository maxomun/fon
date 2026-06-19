export interface TipoDocumento {
  id: number
  codigo: string
  nombre: string
  dte: boolean
  manual: boolean
}

export interface TipoDocumentosListResponse {
  success: boolean
  data: TipoDocumento[]
}
