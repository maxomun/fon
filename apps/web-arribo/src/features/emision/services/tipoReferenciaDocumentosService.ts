import type { TipoReferenciaDocumentosListResponse } from '@/features/emision/types/tipoReferenciaDocumento.types'
import { authenticatedClient } from '@/services/authenticatedClient'

const BASE = '/api/v1/tipo_referencia_documentos'

export const tipoReferenciaDocumentosService = {
  list(query = '', categoria = '') {
    const params = new URLSearchParams()

    if (query.trim()) {
      params.set('q', query.trim())
    }

    if (categoria.trim()) {
      params.set('categoria', categoria.trim())
    }

    const queryString = params.toString()
    return authenticatedClient.get<TipoReferenciaDocumentosListResponse>(
      queryString ? `${BASE}?${queryString}` : BASE,
    )
  },
}
