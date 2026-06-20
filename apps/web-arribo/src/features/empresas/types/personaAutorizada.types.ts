export interface PersonaAutorizada {
  id: number
  rut: string
  nombres: string
  apellido_paterno: string | null
  apellido_materno: string | null
  nombre_completo: string
  email: string
  estado: number
  activa: boolean
  orden: number
  user_id: number | null
  fecha_creacion: string
  fecha_actualizacion: string
  certificado_vigente_id: number | null
  tiene_certificado_vigente: boolean
  puede_eliminarse?: boolean
  fecha_asignacion?: string
  es_administrador_empresa?: boolean
}

export type PersonaAutorizadaInput = {
  rut: string
  nombres: string
  apellido_paterno: string
  apellido_materno: string
  email: string
  estado?: number
  orden?: number
  user_id?: number | null
}

export interface PersonasAutorizadasListResponse {
  success: boolean
  data: PersonaAutorizada[]
  message?: string
}

export interface PersonaAutorizadaResponse {
  success: boolean
  data: PersonaAutorizada
  message?: string
}

export interface PersonaAutorizadaDeleteResponse {
  success: boolean
  message?: string
}

export const ESTADO_PERSONA_ACTIVA = 1
export const ESTADO_PERSONA_INACTIVA = 0

export const emptyPersonaAutorizadaInput = (): PersonaAutorizadaInput => ({
  rut: '',
  nombres: '',
  apellido_paterno: '',
  apellido_materno: '',
  email: '',
  orden: 1,
  estado: ESTADO_PERSONA_ACTIVA,
})

export function personaAutorizadaToInput(persona: PersonaAutorizada): PersonaAutorizadaInput {
  return {
    rut: persona.rut,
    nombres: persona.nombres,
    apellido_paterno: persona.apellido_paterno ?? '',
    apellido_materno: persona.apellido_materno ?? '',
    email: persona.email,
    estado: persona.estado,
    orden: persona.orden,
    user_id: persona.user_id,
  }
}

export function personaAutorizadaPayload(input: PersonaAutorizadaInput) {
  return {
    persona_autorizada: {
      ...input,
      apellido_paterno: input.apellido_paterno || null,
      apellido_materno: input.apellido_materno || null,
      user_id: input.user_id ?? null,
    },
  }
}

export function puedeEliminarPersonaAutorizada(persona: PersonaAutorizada) {
  return persona.puede_eliminarse === true
}
