import type { Producto } from '@/features/productos/types/producto.types'

/** Código SII Factura Electrónica — wizard v1 */
export const FACTURA_ELECTRONICA_CODIGO = '33'

export const MAX_MOVIMIENTOS_GLOBALES = 20
export const MAX_REFERENCIAS = 40

export const EMISION_CODIGO_REFERENCIA_OPCIONES = [
  { value: '1', label: '1 — Anula documento' },
  { value: '2', label: '2 — Corrige texto' },
  { value: '3', label: '3 — Corrige montos' },
  { value: '4', label: '4 — Anulación masiva' },
] as const

export type EmisionTipoMovimiento = 'D' | 'R'
export type EmisionTipoValorGlobal = 'PORCENTAJE' | 'MONTO'
export type EmisionAplicaSobre = 'AFECTO' | 'EXENTO_NO_AFECTO' | 'NO_FACTURABLE'

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
  neto_no_facturable: number
  iva: number
  tasa_iva: number
  total: number
  origen?: 'local' | 'servidor'
}

export interface EmisionDescuentoRecargoGlobal {
  key: string
  tipo_movimiento: EmisionTipoMovimiento
  glosa: string
  tipo_valor: EmisionTipoValorGlobal
  valor: string
  aplica_sobre: EmisionAplicaSobre
}

export interface EmisionDescuentoRecargoGlobalRequest {
  tipo_movimiento: EmisionTipoMovimiento
  glosa?: string
  tipo_valor: EmisionTipoValorGlobal
  valor: number
  aplica_sobre: EmisionAplicaSobre
}

export interface EmisionReferencia {
  key: string
  tipo_documento_referencia: string
  folio_referencia: string
  fecha_referencia: string
  razon_referencia: string
  codigo_referencia: string
  documento_emitido_origen_id: number | null
}

export interface EmisionReferenciaRequest {
  tipo_documento_referencia: string
  folio_referencia: string
  fecha_referencia: string
  razon_referencia?: string
  codigo_referencia?: number
  documento_emitido_origen_id?: number
}

export interface EmisionReferenciaDesdeDocumento {
  documento_emitido_origen_id: number
  tipo_documento_referencia: string
  folio_referencia: string
  fecha_referencia: string
  razon_referencia?: string
}

export interface EmisionMovimientoGlobalCalculado {
  nro_linea: number
  tipo_movimiento: EmisionTipoMovimiento
  glosa: string
  tipo_valor: EmisionTipoValorGlobal
  valor: number
  aplica_sobre: EmisionAplicaSobre
  monto_calculado: number
  orden: number
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
  descuentos_recargos_globales?: EmisionDescuentoRecargoGlobalRequest[]
  referencias?: EmisionReferenciaRequest[]
  enviar_sii?: boolean
}

export interface EmisionCalcularTotalesRequest {
  empresa_id: number
  tipo_documento: number
  receptor: EmisionReceptor
  items: EmisionItemRequest[]
  descuentos_recargos_globales?: EmisionDescuentoRecargoGlobalRequest[]
}

export interface EmisionCalcularTotalesData {
  subtotales: Record<EmisionAplicaSobre, number>
  totales: {
    neto_afecto: number
    neto_exento: number
    neto_no_facturable: number
    tasa_iva: number
    iva: number
    total: number
  }
  descuentos_recargos_globales: EmisionMovimientoGlobalCalculado[]
}

export interface EmisionCalcularTotalesResponse {
  success: boolean
  data?: EmisionCalcularTotalesData
  error?: string
  errors?: string[]
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

export const EMISION_GLOBAL_TIPO_MOV_OPCIONES = [
  { value: 'D' as const, label: 'Descuento' },
  { value: 'R' as const, label: 'Recargo' },
]

export const EMISION_GLOBAL_TIPO_VALOR_OPCIONES = [
  { value: 'PORCENTAJE' as const, label: '%' },
  { value: 'MONTO' as const, label: '$' },
]

export const EMISION_GLOBAL_APLICA_SOBRE_OPCIONES = [
  { value: 'AFECTO' as const, label: 'Neto afecto' },
  { value: 'EXENTO_NO_AFECTO' as const, label: 'Exento / no afecto' },
  { value: 'NO_FACTURABLE' as const, label: 'No facturable' },
]

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

export function emptyEmisionDescuentoRecargoGlobal(): EmisionDescuentoRecargoGlobal {
  return {
    key: crypto.randomUUID(),
    tipo_movimiento: 'D',
    glosa: '',
    tipo_valor: 'PORCENTAJE',
    valor: '',
    aplica_sobre: 'AFECTO',
  }
}

function fechaHoyIsoLocal(): string {
  const fecha = new Date()
  const pad = (valor: number) => String(valor).padStart(2, '0')
  return `${fecha.getFullYear()}-${pad(fecha.getMonth() + 1)}-${pad(fecha.getDate())}`
}

export function emptyEmisionReferencia(): EmisionReferencia {
  return {
    key: crypto.randomUUID(),
    tipo_documento_referencia: '',
    folio_referencia: '',
    fecha_referencia: fechaHoyIsoLocal(),
    razon_referencia: '',
    codigo_referencia: '',
    documento_emitido_origen_id: null,
  }
}
