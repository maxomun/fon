import { authenticatedClient } from '@/services/authenticatedClient'
import type { TipoDocumentosListResponse } from '@/features/empresas/types/tipoDocumento.types'

const BASE = '/api/v1/tipo_documentos'

export const tipoDocumentosService = {
  searchCatalog(query: string, excludeEmpresaId: number) {
    const params = new URLSearchParams()
    params.set('exclude_empresa_id', String(excludeEmpresaId))

    if (query.trim()) {
      params.set('q', query.trim())
    }

    return authenticatedClient.get<TipoDocumentosListResponse>(
      `${BASE}?${params.toString()}`,
    )
  },
}
