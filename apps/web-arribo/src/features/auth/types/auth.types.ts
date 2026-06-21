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

export const PASSWORD_RESET_ONBOARDING_CODES = [
  'ONBOARDING_EMAIL_PENDIENTE',
  'ONBOARDING_INCOMPLETO',
  'PASSWORD_RESET_RATE_LIMITED',
] as const

export type PasswordResetOnboardingCode =
  (typeof PASSWORD_RESET_ONBOARDING_CODES)[number]

export function isPasswordResetOnboardingCode(
  code: string | null | undefined,
): code is PasswordResetOnboardingCode {
  return PASSWORD_RESET_ONBOARDING_CODES.includes(code as PasswordResetOnboardingCode)
}

export interface SolicitarRestablecimientoResponse {
  success: boolean
  message: string
  code?: PasswordResetOnboardingCode | null
  data?: {
    enviado?: boolean
  }
}

export interface RestablecerPasswordInput {
  token: string
  password: string
  password_confirmation: string
}

export interface RestablecerPasswordResponse {
  success: boolean
  message: string
}
