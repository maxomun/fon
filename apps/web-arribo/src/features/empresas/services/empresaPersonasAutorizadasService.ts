import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  PersonaAutorizadaDeleteResponse,
  PersonaAutorizadaResponse,
  PersonasAutorizadasListResponse,
} from '@/features/empresas/types/personaAutorizada.types'

function base(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/personas_autorizadas`
}

export const empresaPersonasAutorizadasService = {
  listAssigned(empresaId: number) {
    return authenticatedClient.get<PersonasAutorizadasListResponse>(base(empresaId))
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

  remove(empresaId: number, personaAutorizadaId: number) {
    return authenticatedClient.delete<PersonaAutorizadaDeleteResponse>(
      `${base(empresaId)}/${personaAutorizadaId}`,
    )
  },
}
