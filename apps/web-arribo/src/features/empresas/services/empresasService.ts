import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  EmpresaDeleteResponse,
  EmpresaInput,
  EmpresaResponse,
  EmpresasListResponse,
} from '@/features/empresas/types/empresa.types'
import { empresaPayload } from '@/features/empresas/types/empresa.types'

const BASE = '/api/v1/empresas'

export const empresasService = {
  list() {
    return authenticatedClient.get<EmpresasListResponse>(BASE)
  },

  get(id: number) {
    return authenticatedClient.get<EmpresaResponse>(`${BASE}/${id}`)
  },

  create(input: EmpresaInput) {
    return authenticatedClient.post<EmpresaResponse>(BASE, empresaPayload(input))
  },

  update(id: number, input: EmpresaInput) {
    return authenticatedClient.patch<EmpresaResponse>(
      `${BASE}/${id}`,
      empresaPayload(input),
    )
  },

  remove(id: number) {
    return authenticatedClient.delete<EmpresaDeleteResponse>(`${BASE}/${id}`)
  },
}
