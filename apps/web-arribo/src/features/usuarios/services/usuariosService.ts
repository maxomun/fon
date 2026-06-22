import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  UsuarioCreateInput,
  UsuarioResponse,
  UsuariosListResponse,
  UsuarioTipoFiltro,
  UsuarioUpdateInput,
} from '@/features/usuarios/types/usuario.types'
import {
  usuarioCreatePayload,
  usuarioUpdatePayload,
} from '@/features/usuarios/types/usuario.types'

const BASE = '/api/v1/usuarios'

export const usuariosService = {
  list(query = '', tipo: UsuarioTipoFiltro = 'todos') {
    const params = new URLSearchParams()
    if (query.trim()) {
      params.set('q', query.trim())
    }
    if (tipo !== 'todos') {
      params.set('tipo', tipo === 'persona' ? 'persona' : tipo)
    }
    const suffix = params.toString() ? `?${params.toString()}` : ''
    return authenticatedClient.get<UsuariosListResponse>(`${BASE}${suffix}`)
  },

  get(id: number) {
    return authenticatedClient.get<UsuarioResponse>(`${BASE}/${id}`)
  },

  create(input: UsuarioCreateInput) {
    return authenticatedClient.post<UsuarioResponse>(BASE, usuarioCreatePayload(input))
  },

  update(id: number, input: UsuarioUpdateInput) {
    return authenticatedClient.patch<UsuarioResponse>(
      `${BASE}/${id}`,
      usuarioUpdatePayload(input),
    )
  },

  setEstado(id: number, activo: boolean) {
    return authenticatedClient.patch<UsuarioResponse>(`${BASE}/${id}/estado`, {
      usuario: { activo },
    })
  },

  reenviarAcceso(id: number) {
    return authenticatedClient.post<UsuarioResponse>(`${BASE}/${id}/reenviar_acceso`)
  },
}
