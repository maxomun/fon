import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  ActecoDeleteResponse,
  ActecoResponse,
  ActecosListResponse,
} from '@/features/empresas/types/acteco.types'

function empresaActecosBase(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/actecos`
}

export const empresaActecosService = {
  listAssigned(empresaId: number) {
    return authenticatedClient.get<ActecosListResponse>(empresaActecosBase(empresaId))
  },

  searchCatalog(query: string, excludeEmpresaId: number) {
    const params = new URLSearchParams()

    if (query.trim()) {
      params.set('q', query.trim())
    }

    params.set('exclude_empresa_id', String(excludeEmpresaId))

    return authenticatedClient.get<ActecosListResponse>(
      `/api/v1/actecos?${params.toString()}`,
    )
  },

  assign(empresaId: number, actecoId: number) {
    return authenticatedClient.post<ActecoResponse>(empresaActecosBase(empresaId), {
      acteco: { acteco_id: actecoId },
    })
  },

  remove(empresaId: number, actecoId: number) {
    return authenticatedClient.delete<ActecoDeleteResponse>(
      `${empresaActecosBase(empresaId)}/${actecoId}`,
    )
  },
}
