export interface RangoFolioTipoDocumento {
  codigo: string
  nombre: string | null
}

export interface RangoFolioNumeros {
  desde: number
  hasta: number
  cantidad: number
}

export interface RangoFolioStats {
  disponibles: number
  usados: number
  total: number
  anulados?: number
  reservados?: number
}

export interface RangoFolio {
  id: number
  empresa_id: number
  tipo_documento: RangoFolioTipoDocumento
  rango: RangoFolioNumeros
  folios: RangoFolioStats
  fecha_autorizacion: string
  fecha_subida: string
  fecha_ultimo_uso: string | null
  subido_por: string
  archivo: string
  proximo_folio_disponible?: number | null
}

export interface RangosFoliosListResponse {
  success: boolean
  data: RangoFolio[]
}

export interface RangoFolioResponse {
  success: boolean
  data: RangoFolio
  message?: string
}

export interface RangoFolioDeleteResponse {
  success: boolean
  message?: string
}

export function formatRangoFolios(rango: RangoFolioNumeros) {
  return `${rango.desde} – ${rango.hasta}`
}

export function formatFechaRango(value: string | null) {
  if (!value) {
    return '—'
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleString('es-CL')
}

export function puedeEliminarRango(rango: RangoFolio) {
  return rango.folios.usados === 0
}
