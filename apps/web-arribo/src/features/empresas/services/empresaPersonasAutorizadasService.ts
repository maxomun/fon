import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  PersonaAutorizadaDeleteResponse,
  PersonaAutorizadaInput,
  PersonaAutorizadaResponse,
  PersonasAutorizadasListResponse,
} from '@/features/empresas/types/personaAutorizada.types'
import { personaAutorizadaPayload } from '@/features/empresas/types/personaAutorizada.types'

function base(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/personas_autorizadas`
}

export const empresaPersonasAutorizadasService = {
  listAssigned(empresaId: number) {
    return authenticatedClient.get<PersonasAutorizadasListResponse>(base(empresaId))
  },

  searchAvailable(empresaId: number, query = '') {
    const params = new URLSearchParams()
    if (query.trim()) {
      params.set('q', query.trim())
    }
    const suffix = params.toString() ? `?${params.toString()}` : ''
    return authenticatedClient.get<PersonasAutorizadasListResponse>(
      `${base(empresaId)}/buscar${suffix}`,
    )
  },

  assign(
    empresaId: number,
    personaAutorizadaId: number,
    options?: { esAdministradorEmpresa?: boolean },
  ) {
    return authenticatedClient.post<PersonaAutorizadaResponse>(base(empresaId), {
      persona_autorizada: {
        persona_autorizada_id: personaAutorizadaId,
        es_administrador_empresa: options?.esAdministradorEmpresa ?? false,
      },
    })
  },

  createAndAssign(
    empresaId: number,
    input: PersonaAutorizadaInput,
    options?: { esAdministradorEmpresa?: boolean },
  ) {
    return authenticatedClient.post<PersonaAutorizadaResponse>(base(empresaId), {
      persona_autorizada: {
        ...personaAutorizadaPayload(input).persona_autorizada,
        es_administrador_empresa: options?.esAdministradorEmpresa ?? false,
      },
    })
  },

  updatePersona(empresaId: number, personaAutorizadaId: number, input: PersonaAutorizadaInput) {
    return authenticatedClient.patch<PersonaAutorizadaResponse>(
      `${base(empresaId)}/${personaAutorizadaId}`,
      personaAutorizadaPayload(input),
    )
  },

  updateAdminRole(
    empresaId: number,
    personaAutorizadaId: number,
    esAdministradorEmpresa: boolean,
  ) {
    return authenticatedClient.patch<PersonaAutorizadaResponse>(
      `${base(empresaId)}/${personaAutorizadaId}`,
      {
        persona_autorizada: {
          es_administrador_empresa: esAdministradorEmpresa,
        },
      },
    )
  },

  reenviarOnboarding(empresaId: number, personaAutorizadaId: number) {
    return authenticatedClient.post<PersonaAutorizadaResponse>(
      `${base(empresaId)}/${personaAutorizadaId}/reenviar_onboarding`,
    )
  },

  remove(empresaId: number, personaAutorizadaId: number) {
    return authenticatedClient.delete<PersonaAutorizadaDeleteResponse>(
      `${base(empresaId)}/${personaAutorizadaId}`,
    )
  },
}
