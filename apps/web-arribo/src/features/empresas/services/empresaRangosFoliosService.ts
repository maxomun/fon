import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  RangoFolioDeleteResponse,
  RangoFolioResponse,
  RangosFoliosListResponse,
} from '@/features/empresas/types/rangoFolio.types'

function baseUrl(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/rangos_folios`
}

export const empresaRangosFoliosService = {
  list(empresaId: number) {
    return authenticatedClient.get<RangosFoliosListResponse>(baseUrl(empresaId))
  },

  get(empresaId: number, rangoFolioId: number) {
    return authenticatedClient.get<RangoFolioResponse>(
      `${baseUrl(empresaId)}/${rangoFolioId}`,
    )
  },

  upload(empresaId: number, archivo: File) {
    const formData = new FormData()
    formData.append('archivo', archivo)

    return authenticatedClient.postFormData<RangoFolioResponse>(
      baseUrl(empresaId),
      formData,
    )
  },

  remove(empresaId: number, rangoFolioId: number) {
    return authenticatedClient.delete<RangoFolioDeleteResponse>(
      `${baseUrl(empresaId)}/${rangoFolioId}`,
    )
  },
}
