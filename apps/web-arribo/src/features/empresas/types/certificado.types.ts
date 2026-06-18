export interface CertificadoPersonaResumen {
  id: number
  rut: string
  nombre_completo: string
  orden: number
}

export interface Certificado {
  id: number
  persona_autorizada_id: number
  persona: CertificadoPersonaResumen
  fecha_adjuncion: string
  vigente: boolean
  fecha_caducacion: string | null
  responsable: string | null
  completo: boolean
  caducado: boolean
  utilizable_para_firma: boolean
  archivo_crs_adjunto: boolean
  archivo_key_adjunto: boolean
}

export interface CertificadosListResponse {
  success: boolean
  data: Certificado[]
  message?: string
}

export interface CertificadoResponse {
  success: boolean
  data: Certificado
  message?: string
}

export interface CertificadoVerificarResponse {
  success: boolean
  data: {
    certificado_id: number
    persona_autorizada_id: number
    certificado_valido: boolean
    utilizable_para_firma: boolean
    verificaciones: Record<string, boolean>
    info_certificado: Record<string, string>
  }
  message?: string
}

export interface CertificadoDeleteResponse {
  success: boolean
  message?: string
}
