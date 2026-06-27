import type { Producto } from '@/features/productos/types/producto.types'

/** Código SII Factura Electrónica — wizard v1 */
export const FACTURA_ELECTRONICA_CODIGO = '33'

export interface EmisionReceptor {
  rut: string
  razon_social: string
  giro: string
  direccion: string
  email: string
}

export interface EmisionLinea {
  key: string
  producto_id: number
  cantidad: string
  descuento_pct: string
}

export interface EmisionLineaCalculada {
  producto: Producto
  cantidad: number
  descuento_pct: number
  subtotal: number
  descuento_monto: number
  neto: number
  afecto: boolean
}

export interface EmisionTotales {
  neto_afecto: number
  neto_exento: number
  iva: number
  tasa_iva: number
  total: number
}

export interface EmisionItemRequest {
  producto_id: number
  cantidad: number
  descuento_pct?: number
}

export interface EmisionGenerarRequest {
  empresa_id: number
  tipo_documento: number
  receptor: EmisionReceptor
  items: EmisionItemRequest[]
  enviar_sii?: boolean
}

export interface DocumentoEmitidoResumen {
  id: number
  folio: number
  tipo_documento: string
  rut_receptor: string
  razon_social_receptor: string
  dte_envio_id?: number | null
}

export interface EmisionGenerarResponse {
  success: boolean
  message?: string
  error?: string
  fase?: string
  errors?: string[]
  data?: {
    dte_envio_id?: number
    xml_archivado?: boolean
    folios_usados: number[]
    documentos_emitidos: DocumentoEmitidoResumen[]
    total_documentos: number
    envio_sii?: {
      enviado: boolean
      omitido: boolean
      pendiente: boolean
      track_id?: string | null
      error?: string
    }
  }
}

export function emptyEmisionReceptor(): EmisionReceptor {
  return {
    rut: '',
    razon_social: '',
    giro: '',
    direccion: '',
    email: '',
  }
}

export function emptyEmisionLinea(): EmisionLinea {
  return {
    key: crypto.randomUUID(),
    producto_id: 0,
    cantidad: '1',
    descuento_pct: '0',
  }
}
