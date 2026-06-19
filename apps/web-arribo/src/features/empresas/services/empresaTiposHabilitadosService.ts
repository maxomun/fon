import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  TipoHabilitadoDeleteResponse,
  TipoHabilitadoInput,
  TipoHabilitadoResponse,
  TipoHabilitadoUpdateInput,
  TiposHabilitadosListResponse,
} from '@/features/empresas/types/tipoHabilitado.types'
import {
  tipoHabilitadoCreatePayload,
  tipoHabilitadoUpdatePayload,
} from '@/features/empresas/types/tipoHabilitado.types'

function baseUrl(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/tipos_habilitados`
}

export const empresaTiposHabilitadosService = {
  listAssigned(empresaId: number) {
    return authenticatedClient.get<TiposHabilitadosListResponse>(baseUrl(empresaId))
  },

  assign(empresaId: number, input: TipoHabilitadoInput) {
    return authenticatedClient.post<TipoHabilitadoResponse>(
      baseUrl(empresaId),
      tipoHabilitadoCreatePayload(input),
    )
  },

  update(empresaId: number, tipoHabilitadoId: number, input: TipoHabilitadoUpdateInput) {
    return authenticatedClient.patch<TipoHabilitadoResponse>(
      `${baseUrl(empresaId)}/${tipoHabilitadoId}`,
      tipoHabilitadoUpdatePayload(input),
    )
  },

  remove(empresaId: number, tipoHabilitadoId: number) {
    return authenticatedClient.delete<TipoHabilitadoDeleteResponse>(
      `${baseUrl(empresaId)}/${tipoHabilitadoId}`,
    )
  },
}
