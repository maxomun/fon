export interface LoginCredentials {
  email: string
  password: string
}

export interface AuthTokens {
  access_token: string
  token_type: string
  expires_at: string
  expires_in: number
  refresh_token: string
  refresh_expires_at: string
}

export interface UserEmpresaResumen {
  id: number
  rut: string
  razon_social: string
  es_administrador: boolean
  puede_firmar: boolean
}

export interface UserRole {
  codigo: string
  descripcion: string
  esadmin: boolean
}

export interface UserProfile {
  id: number
  email: string
  username: string
  lenguaje: string
  nombres?: string | null
  apellido_paterno?: string | null
  apellido_materno?: string | null
  nombre_completo?: string | null
  persona_autorizada_id?: number | null
  acceso_global: boolean
  empresas: UserEmpresaResumen[]
  roles: UserRole[]
  email_verificado?: boolean
  onboarding_completado?: boolean
  requiere_verificacion_email?: boolean
  requiere_onboarding?: boolean
  debe_cambiar_password?: boolean
}

export interface LoginResponse extends AuthTokens {
  success: boolean
  message: string
  user?: UserProfile
}

export interface MeResponse {
  success: boolean
  user: UserProfile
}

export interface RefreshResponse extends AuthTokens {
  success: boolean
  message: string
  user?: UserProfile
}

export const AUTH_ONBOARDING_BLOCK_CODES = [
  'EMAIL_NOT_VERIFIED',
  'ONBOARDING_INCOMPLETE',
] as const

export type AuthOnboardingBlockCode = (typeof AUTH_ONBOARDING_BLOCK_CODES)[number]

export function isAuthOnboardingBlockCode(
  code: string | undefined,
): code is AuthOnboardingBlockCode {
  return AUTH_ONBOARDING_BLOCK_CODES.includes(code as AuthOnboardingBlockCode)
}

export interface ReenviarVerificacionResponse {
  success: boolean
  message: string
}
