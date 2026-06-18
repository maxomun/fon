import { authenticatedClient } from '@/services/authenticatedClient'
import type { PaisesListResponse } from '@/features/empresas/types/pais.types'

const BASE = '/api/v1/paises'

export const paisesService = {
  list() {
    return authenticatedClient.get<PaisesListResponse>(BASE)
  },
}
