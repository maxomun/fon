import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  ImpuestoValorDeleteResponse,
  ImpuestoValorInput,
  ImpuestoValorResponse,
  ImpuestoValoresListResponse,
} from '@/features/impuestos/types/impuestoValor.types'
import { impuestoValorPayload } from '@/features/impuestos/types/impuestoValor.types'

function basePath(impuestoId: number) {
  return `/api/v1/impuestos/${impuestoId}/valores`
}

export const impuestoValoresService = {
  list(impuestoId: number) {
    return authenticatedClient.get<ImpuestoValoresListResponse>(basePath(impuestoId))
  },

  create(impuestoId: number, input: ImpuestoValorInput) {
    return authenticatedClient.post<ImpuestoValorResponse>(
      basePath(impuestoId),
      impuestoValorPayload(input),
    )
  },

  update(impuestoId: number, valorId: number, input: ImpuestoValorInput) {
    return authenticatedClient.patch<ImpuestoValorResponse>(
      `${basePath(impuestoId)}/${valorId}`,
      impuestoValorPayload(input),
    )
  },

  remove(impuestoId: number, valorId: number) {
    return authenticatedClient.delete<ImpuestoValorDeleteResponse>(
      `${basePath(impuestoId)}/${valorId}`,
    )
  },
}
