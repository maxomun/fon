import type { ImpuestoValor } from '@/features/impuestos/types/impuestoValor.types'

export interface ImpuestoPais {
  id: number
  codigo: string
  nombre: string
}

export interface Impuesto {
  id: number
  pais_id: number
  pais: ImpuestoPais
  nombre: string
  abreviacion: string
  valor_vigente: number | null
  tiene_productos: boolean
  valores?: ImpuestoValor[]
}

export type ImpuestoInput = {
  pais_id: number
  nombre: string
  abreviacion: string
}

export type ImpuestoUpdateInput = {
  nombre: string
  abreviacion: string
}

export interface ImpuestosListResponse {
  success: boolean
  data: Impuesto[]
}

export interface ImpuestoResponse {
  success: boolean
  data: Impuesto
  message?: string
}

export interface ImpuestoDeleteResponse {
  success: boolean
  message?: string
}

export const emptyImpuestoInput = (paisId = 0): ImpuestoInput => ({
  pais_id: paisId,
  nombre: '',
  abreviacion: '',
})

export function impuestoToUpdateInput(impuesto: Impuesto): ImpuestoUpdateInput {
  return {
    nombre: impuesto.nombre,
    abreviacion: impuesto.abreviacion,
  }
}

export function impuestoPayload(input: ImpuestoInput) {
  return { impuesto: input }
}

export function impuestoUpdatePayload(input: ImpuestoUpdateInput) {
  return { impuesto: input }
}

export function formatValorVigente(valor: number | null) {
  if (valor === null || valor === undefined) {
    return '—'
  }

  return `${valor}%`
}
