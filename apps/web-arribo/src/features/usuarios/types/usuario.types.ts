import type { UserRole } from '@/features/auth/types/auth.types'

export type UsuarioTipoCuenta = 'plataforma' | 'persona_autorizada'

export type UsuarioTipoFiltro = 'todos' | 'plataforma' | 'persona'

export interface UsuarioEmpresaResumen {
  id: number
  rut: string
  razon_social: string
  es_administrador_empresa: boolean
}

export interface UsuarioPersonaAutorizadaDetalle {
  id: number
  rut: string
  nombres: string
  apellido_paterno: string | null
  apellido_materno: string | null
  nombre_completo: string
  email: string
  activa: boolean
  empresas: UsuarioEmpresaResumen[]
}

export interface Usuario {
  id: number
  email: string
  username: string
  lenguaje: string
  nombres: string | null
  apellido_paterno: string | null
  apellido_materno: string | null
  nombre_completo: string | null
  visible: boolean
  estado: number
  activo: boolean
  tipo_cuenta: UsuarioTipoCuenta
  persona_autorizada_id: number | null
  persona_autorizada?: UsuarioPersonaAutorizadaDetalle | null
  puede_editar: boolean
  acceso_global: boolean
  roles: UserRole[]
  email_verificado: boolean
  onboarding_completado: boolean
  requiere_verificacion_email: boolean
  requiere_onboarding: boolean
  debe_cambiar_password: boolean
  timestamp: string
}

export type UsuarioCreateInput = {
  email: string
  username?: string
  nombres: string
  apellido_paterno?: string
  apellido_materno?: string
  lenguaje?: string
  visible?: boolean
  password?: string
  password_confirmation?: string
  administrador_fon?: boolean
  enviar_acceso?: boolean
}

export type UsuarioUpdateInput = {
  email?: string
  username?: string
  nombres?: string
  apellido_paterno?: string
  apellido_materno?: string
  lenguaje?: string
  visible?: boolean
  password?: string
  password_confirmation?: string
  administrador_fon?: boolean
}

export interface UsuariosListResponse {
  success: boolean
  data: Usuario[]
}

export interface UsuarioResponse {
  success: boolean
  data: Usuario
  message?: string
}

export const ESTADO_USUARIO_ACTIVO = 1

export function emptyUsuarioCreateInput(): UsuarioCreateInput {
  return {
    email: '',
    username: '',
    nombres: '',
    apellido_paterno: '',
    apellido_materno: '',
    lenguaje: 'es',
    administrador_fon: true,
    enviar_acceso: false,
  }
}

export function usuarioToUpdateInput(usuario: Usuario): UsuarioUpdateInput {
  return {
    email: usuario.email,
    username: usuario.username,
    nombres: usuario.nombres ?? '',
    apellido_paterno: usuario.apellido_paterno ?? '',
    apellido_materno: usuario.apellido_materno ?? '',
    lenguaje: usuario.lenguaje,
    visible: usuario.visible,
    administrador_fon: usuario.acceso_global,
  }
}

export function usuarioCreatePayload(input: UsuarioCreateInput) {
  const payload: Record<string, unknown> = {
    email: input.email.trim(),
    nombres: input.nombres.trim(),
    apellido_paterno: input.apellido_paterno?.trim() || null,
    apellido_materno: input.apellido_materno?.trim() || null,
    lenguaje: input.lenguaje ?? 'es',
    administrador_fon: input.administrador_fon ?? true,
  }

  if (input.username?.trim()) {
    payload.username = input.username.trim()
  }

  if (input.visible !== undefined) {
    payload.visible = input.visible
  }

  if (input.password) {
    payload.password = input.password
    payload.password_confirmation = input.password_confirmation ?? input.password
  } else if (input.enviar_acceso) {
    payload.enviar_acceso = true
  }

  return { usuario: payload }
}

export function usuarioUpdatePayload(input: UsuarioUpdateInput) {
  const payload: Record<string, unknown> = {}

  if (input.email !== undefined) payload.email = input.email.trim()
  if (input.username !== undefined) payload.username = input.username.trim()
  if (input.nombres !== undefined) payload.nombres = input.nombres.trim()
  if (input.apellido_paterno !== undefined) {
    payload.apellido_paterno = input.apellido_paterno.trim() || null
  }
  if (input.apellido_materno !== undefined) {
    payload.apellido_materno = input.apellido_materno.trim() || null
  }
  if (input.lenguaje !== undefined) payload.lenguaje = input.lenguaje
  if (input.visible !== undefined) payload.visible = input.visible
  if (input.administrador_fon !== undefined) payload.administrador_fon = input.administrador_fon

  if (input.password) {
    payload.password = input.password
    payload.password_confirmation = input.password_confirmation ?? input.password
  }

  return { usuario: payload }
}

export function usuarioTipoLabel(tipo: UsuarioTipoCuenta) {
  return tipo === 'plataforma' ? 'Plataforma' : 'Persona autorizada'
}

export function usuarioRolesLabel(usuario: Usuario) {
  if (usuario.roles.length === 0) {
    return '—'
  }

  return usuario.roles.map((rol) => rol.descripcion || rol.codigo).join(', ')
}

export function esUsuarioPlataformaEditable(usuario: Usuario) {
  return usuario.puede_editar && usuario.tipo_cuenta === 'plataforma'
}
