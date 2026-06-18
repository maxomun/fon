import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  PersonaAutorizadaDeleteResponse,
  PersonaAutorizadaInput,
  PersonaAutorizadaResponse,
  PersonasAutorizadasListResponse,
} from '@/features/empresas/types/personaAutorizada.types'
import { personaAutorizadaPayload } from '@/features/empresas/types/personaAutorizada.types'

const BASE = '/api/v1/personas_autorizadas'

export const personaAutorizadaService = {
  list(query = '', excludeEmpresaId?: number) {
    const params = new URLSearchParams()
    if (query.trim()) {
      params.set('q', query.trim())
    }
    if (excludeEmpresaId !== undefined) {
      params.set('exclude_empresa_id', String(excludeEmpresaId))
    }
    const suffix = params.toString() ? `?${params.toString()}` : ''
    return authenticatedClient.get<PersonasAutorizadasListResponse>(`${BASE}${suffix}`)
  },

  create(input: PersonaAutorizadaInput) {
    return authenticatedClient.post<PersonaAutorizadaResponse>(
      BASE,
      personaAutorizadaPayload(input),
    )
  },

  update(id: number, input: PersonaAutorizadaInput) {
    return authenticatedClient.patch<PersonaAutorizadaResponse>(
      `${BASE}/${id}`,
      personaAutorizadaPayload(input),
    )
  },

  remove(id: number) {
    return authenticatedClient.delete<PersonaAutorizadaDeleteResponse>(`${BASE}/${id}`)
  },
}
