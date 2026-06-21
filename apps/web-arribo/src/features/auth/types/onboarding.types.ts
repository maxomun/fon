export interface OnboardingStatus {
  email_verificado: boolean
  onboarding_completado: boolean
  requiere_verificacion_email?: boolean
  requiere_onboarding?: boolean
  debe_cambiar_password?: boolean
}

export interface VerificarEmailResponse {
  success: boolean
  message: string
  data: {
    setup_token: string
    email_verificado: boolean
    onboarding_completado: boolean
    requiere_onboarding: boolean
  }
}

export interface EstablecerPasswordResponse {
  success: boolean
  message: string
  data: OnboardingStatus
}

export interface EstablecerPasswordInput {
  token: string
  password: string
  password_confirmation: string
}

export type EstablecerPasswordFormErrors = Partial<
  Record<'password' | 'password_confirmation', string>
>
