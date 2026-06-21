import type { EstablecerPasswordFormErrors } from '@/features/auth/types/onboarding.types'

export function validateOnboardingPassword(
  password: string,
  passwordConfirmation: string,
): EstablecerPasswordFormErrors {
  const errors: EstablecerPasswordFormErrors = {}

  if (!password) {
    errors.password = 'La contraseña es requerida'
  } else if (password.length < 6) {
    errors.password = 'La contraseña debe tener al menos 6 caracteres'
  }

  if (!passwordConfirmation) {
    errors.password_confirmation = 'Confirme la contraseña'
  } else if (password !== passwordConfirmation) {
    errors.password_confirmation = 'Las contraseñas no coinciden'
  }

  return errors
}

export function hasOnboardingPasswordErrors(errors: EstablecerPasswordFormErrors) {
  return Object.keys(errors).length > 0
}
