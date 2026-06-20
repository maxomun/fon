export interface EmpresaPais {
  id: number
  codigo: string
  nombre: string
}

export interface Empresa {
  id: number
  pais_id: number
  pais: EmpresaPais
  rut: string
  razon_social: string
  nombre_fantasia: string
  giro: string
  direccion: string
  resolucion_timbre: string
  fecha_resolucion: string
  numero_resolucion: number
  telefono1: string | null
  telefono2: string | null
  archivo_logo: string | null
  fecha_creacion: string
  fecha_actualizacion: string
  tiene_certificado_vigente: boolean
  fecha_caducacion_certificado: string | null
  es_administrador?: boolean
}

export type EmpresaInput = Omit<
  Empresa,
  | 'id'
  | 'pais'
  | 'fecha_creacion'
  | 'fecha_actualizacion'
  | 'tiene_certificado_vigente'
  | 'fecha_caducacion_certificado'
>

export interface EmpresasListResponse {
  success: boolean
  data: Empresa[]
}

export interface EmpresaResponse {
  success: boolean
  data: Empresa
  message?: string
}

export interface EmpresaDeleteResponse {
  success: boolean
  message?: string
}

export const emptyEmpresaInput = (paisId = 0): EmpresaInput => ({
  pais_id: paisId,
  rut: '',
  razon_social: '',
  nombre_fantasia: '',
  giro: '',
  direccion: '',
  resolucion_timbre: '',
  fecha_resolucion: '',
  numero_resolucion: 0,
  telefono1: '',
  telefono2: '',
  archivo_logo: '',
})

export function empresaToInput(empresa: Empresa): EmpresaInput {
  return {
    pais_id: empresa.pais_id,
    rut: empresa.rut,
    razon_social: empresa.razon_social,
    nombre_fantasia: empresa.nombre_fantasia,
    giro: empresa.giro,
    direccion: empresa.direccion,
    resolucion_timbre: empresa.resolucion_timbre,
    fecha_resolucion: empresa.fecha_resolucion,
    numero_resolucion: empresa.numero_resolucion,
    telefono1: empresa.telefono1 ?? '',
    telefono2: empresa.telefono2 ?? '',
    archivo_logo: empresa.archivo_logo ?? '',
  }
}

export function empresaPayload(input: EmpresaInput) {
  return {
    empresa: {
      ...input,
      telefono1: input.telefono1 || null,
      telefono2: input.telefono2 || null,
      archivo_logo: input.archivo_logo || null,
    },
  }
}
