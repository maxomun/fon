import type { TipoDocumento } from '@/features/empresas/types/tipoDocumento.types'

export interface TipoHabilitado {
  id: number
  empresa_id: number
  tipo_documento: Pick<TipoDocumento, 'id' | 'codigo' | 'nombre' | 'dte'>
  fecha_habilitacion: string
  tiene_rangos_folio: boolean
  tiene_documentos_emitidos: boolean
  folios_disponibles: number
}

export type TipoHabilitadoInput = {
  tipo_documento_id: number
  fecha_habilitacion?: string
}

export type TipoHabilitadoUpdateInput = {
  fecha_habilitacion: string
}

export interface TiposHabilitadosListResponse {
  success: boolean
  data: TipoHabilitado[]
}

export interface TipoHabilitadoResponse {
  success: boolean
  data: TipoHabilitado
  message?: string
}

export interface TipoHabilitadoDeleteResponse {
  success: boolean
  message?: string
}

export function formatFechaHabilitacion(value: string) {
  if (!value) {
    return '—'
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleString('es-CL')
}

export function toDateTimeLocalValue(value: string | Date) {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) {
    return ''
  }

  const offset = date.getTimezoneOffset()
  const local = new Date(date.getTime() - offset * 60_000)
  return local.toISOString().slice(0, 16)
}

export function fromDateTimeLocalValue(value: string) {
  if (!value) {
    return value
  }

  return new Date(value).toISOString()
}

export function defaultFechaHabilitacionInput() {
  return toDateTimeLocalValue(new Date())
}

export function tipoHabilitadoToUpdateInput(
  tipo: TipoHabilitado,
): TipoHabilitadoUpdateInput {
  return {
    fecha_habilitacion: toDateTimeLocalValue(tipo.fecha_habilitacion),
  }
}

export function tipoHabilitadoCreatePayload(input: TipoHabilitadoInput) {
  return {
    tipo_habilitado: {
      tipo_documento_id: input.tipo_documento_id,
      fecha_habilitacion: input.fecha_habilitacion
        ? fromDateTimeLocalValue(input.fecha_habilitacion)
        : undefined,
    },
  }
}

export function tipoHabilitadoUpdatePayload(input: TipoHabilitadoUpdateInput) {
  return {
    tipo_habilitado: {
      fecha_habilitacion: fromDateTimeLocalValue(input.fecha_habilitacion),
    },
  }
}

export function puedeQuitarHabilitacion(tipo: TipoHabilitado) {
  return !tipo.tiene_rangos_folio && !tipo.tiene_documentos_emitidos
}
