export interface ImpuestoValor {
  id: number
  impuesto_id: number
  valor: number
  fecha_activacion: string
  fecha_caducacion: string | null
  vigente: boolean
}

export type ImpuestoValorInput = {
  valor: number
  fecha_activacion: string
  fecha_caducacion?: string | null
}

export interface ImpuestoValoresListResponse {
  success: boolean
  data: ImpuestoValor[]
}

export interface ImpuestoValorResponse {
  success: boolean
  data: ImpuestoValor
  message?: string
}

export interface ImpuestoValorDeleteResponse {
  success: boolean
  message?: string
}

export const emptyImpuestoValorInput = (): ImpuestoValorInput => ({
  valor: 0,
  fecha_activacion: toDateTimeLocalValue(new Date()),
  fecha_caducacion: null,
})

export function impuestoValorToInput(valor: ImpuestoValor): ImpuestoValorInput {
  return {
    valor: valor.valor,
    fecha_activacion: toDateTimeLocalValue(valor.fecha_activacion),
    fecha_caducacion: valor.fecha_caducacion
      ? toDateTimeLocalValue(valor.fecha_caducacion)
      : null,
  }
}

export function impuestoValorPayload(input: ImpuestoValorInput) {
  return {
    impuesto_valor: {
      valor: input.valor,
      fecha_activacion: fromDateTimeLocalValue(input.fecha_activacion),
      fecha_caducacion: input.fecha_caducacion
        ? fromDateTimeLocalValue(input.fecha_caducacion)
        : null,
    },
  }
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

export function formatDateTime(value: string | null) {
  if (!value) {
    return '—'
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleString('es-CL')
}

export function formatSiNo(value: boolean) {
  return value ? 'Sí' : 'No'
}
