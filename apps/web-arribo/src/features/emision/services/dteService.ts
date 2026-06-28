import type {
  EmisionCalcularTotalesRequest,
  EmisionCalcularTotalesResponse,
  EmisionGenerarRequest,
  EmisionGenerarResponse,
} from '@/features/emision/types/emision.types'
import { authenticatedClient } from '@/services/authenticatedClient'

export const dteService = {
  calcularTotales(payload: EmisionCalcularTotalesRequest) {
    return authenticatedClient.post<EmisionCalcularTotalesResponse>(
      '/api/v1/dte/calcular_totales',
      payload,
    )
  },

  generar(payload: EmisionGenerarRequest) {
    return authenticatedClient.post<EmisionGenerarResponse>('/api/v1/dte/generar', payload)
  },
}
