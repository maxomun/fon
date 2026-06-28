import { authenticatedClient } from '@/services/authenticatedClient'
import type { EmpresaLogoResponse } from '@/features/empresas/types/empresa.types'

function baseUrl(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/logo`
}

export const empresaLogoService = {
  upload(empresaId: number, archivo: File) {
    const formData = new FormData()
    formData.append('archivo', archivo)

    return authenticatedClient.postFormData<EmpresaLogoResponse>(
      baseUrl(empresaId),
      formData,
    )
  },

  remove(empresaId: number) {
    return authenticatedClient.delete<EmpresaLogoResponse>(baseUrl(empresaId))
  },

  fetchBlob(empresaId: number) {
    return authenticatedClient.download(baseUrl(empresaId), {
      fallbackFilename: 'logo.png',
    })
  },
}
