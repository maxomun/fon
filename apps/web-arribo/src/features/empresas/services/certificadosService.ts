import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  CertificadoDeleteResponse,
  CertificadoResponse,
  CertificadosListResponse,
  CertificadoVerificarResponse,
} from '@/features/empresas/types/certificado.types'

const BASE = '/api/v1/certificados'

export const certificadosService = {
  listByEmpresa(empresaId: number) {
    return authenticatedClient.get<CertificadosListResponse>(
      `${BASE}/listar?empresa_id=${empresaId}`,
    )
  },

  listByPersona(personaAutorizadaId: number) {
    return authenticatedClient.get<CertificadosListResponse>(
      `${BASE}/listar?persona_autorizada_id=${personaAutorizadaId}`,
    )
  },

  upload(input: {
    personaAutorizadaId: number
    empresaId: number
    archivoCrs: File
    archivoKey: File
    fraseClave: string
  }) {
    const formData = new FormData()
    formData.append('persona_autorizada_id', String(input.personaAutorizadaId))
    formData.append('empresa_id', String(input.empresaId))
    formData.append('archivo_crs', input.archivoCrs)
    formData.append('archivo_key', input.archivoKey)
    formData.append('frase_clave', input.fraseClave)

    return authenticatedClient.postFormData<CertificadoResponse>(`${BASE}/crear`, formData)
  },

  verify(certificadoId: number) {
    return authenticatedClient.post<CertificadoVerificarResponse>(`${BASE}/verificar`, {
      certificado_id: certificadoId,
    })
  },

  deactivate(certificadoId: number) {
    return authenticatedClient.delete<CertificadoDeleteResponse>(
      `${BASE}/eliminar?certificado_id=${certificadoId}`,
    )
  },
}
