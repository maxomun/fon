import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  ImpuestoDeleteResponse,
  ImpuestoInput,
  ImpuestoResponse,
  ImpuestosListResponse,
  ImpuestoUpdateInput,
} from '@/features/impuestos/types/impuesto.types'
import {
  impuestoPayload,
  impuestoUpdatePayload,
} from '@/features/impuestos/types/impuesto.types'

const BASE = '/api/v1/impuestos'

export const impuestosService = {
  list(paisId: number) {
    return authenticatedClient.get<ImpuestosListResponse>(`${BASE}?pais_id=${paisId}`)
  },

  get(id: number) {
    return authenticatedClient.get<ImpuestoResponse>(`${BASE}/${id}`)
  },

  create(input: ImpuestoInput) {
    return authenticatedClient.post<ImpuestoResponse>(BASE, impuestoPayload(input))
  },

  update(id: number, input: ImpuestoUpdateInput) {
    return authenticatedClient.patch<ImpuestoResponse>(
      `${BASE}/${id}`,
      impuestoUpdatePayload(input),
    )
  },

  remove(id: number) {
    return authenticatedClient.delete<ImpuestoDeleteResponse>(`${BASE}/${id}`)
  },
}
