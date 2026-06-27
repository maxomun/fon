import type {
  EmisionGenerarRequest,
  EmisionGenerarResponse,
} from '@/features/emision/types/emision.types'
import { authenticatedClient } from '@/services/authenticatedClient'

export const dteService = {
  generar(payload: EmisionGenerarRequest) {
    return authenticatedClient.post<EmisionGenerarResponse>('/api/v1/dte/generar', payload)
  },
}
