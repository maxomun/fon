import type { LoginCredentials } from '@/features/auth/types/auth.types'

export type LoginFormErrors = Partial<Record<keyof LoginCredentials, string>>

export function validateLoginForm(values: LoginCredentials): LoginFormErrors {
  const errors: LoginFormErrors = {}
  const email = values.email.trim()

  if (!email) {
    errors.email = 'El email es requerido'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    errors.email = 'Ingresa un email válido'
  }

  if (!values.password) {
    errors.password = 'La contraseña es requerida'
  } else if (values.password.length < 6) {
    errors.password = 'La contraseña debe tener al menos 6 caracteres'
  }

  return errors
}

export function hasLoginFormErrors(errors: LoginFormErrors) {
  return Object.keys(errors).length > 0
}
