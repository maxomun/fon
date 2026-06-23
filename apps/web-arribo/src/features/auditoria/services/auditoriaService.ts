import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  AuditEventDetailResponse,
  AuditEventListResponse,
  AuditoriaFiltros,
} from '@/features/auditoria/types/auditEvent.types'

const BASE = '/api/v1/auditoria'

function buildQuery(filtros: AuditoriaFiltros, page: number) {
  const params = new URLSearchParams()

  if (filtros.q.trim()) {
    params.set('q', filtros.q.trim())
  }
  if (filtros.categoria) {
    params.set('categoria', filtros.categoria)
  }
  if (filtros.resultado) {
    params.set('resultado', filtros.resultado)
  }
  if (filtros.desde) {
    params.set('desde', filtros.desde)
  }
  if (filtros.hasta) {
    params.set('hasta', filtros.hasta)
  }
  if (filtros.empresa_id.trim()) {
    params.set('empresa_id', filtros.empresa_id.trim())
  }

  params.set('page', String(page))
  params.set('per_page', '25')

  return `?${params.toString()}`
}

export const auditoriaService = {
  listGlobal(filtros: AuditoriaFiltros, page = 1) {
    return authenticatedClient.get<AuditEventListResponse>(`${BASE}${buildQuery(filtros, page)}`)
  },

  getGlobal(id: number) {
    return authenticatedClient.get<AuditEventDetailResponse>(`${BASE}/${id}`)
  },

  listEmpresa(empresaId: number, filtros: AuditoriaFiltros, page = 1) {
    return authenticatedClient.get<AuditEventListResponse>(
      `/api/v1/empresas/${empresaId}/auditoria${buildQuery(filtros, page)}`,
    )
  },

  getEmpresa(empresaId: number, id: number) {
    return authenticatedClient.get<AuditEventDetailResponse>(
      `/api/v1/empresas/${empresaId}/auditoria/${id}`,
    )
  },
}
