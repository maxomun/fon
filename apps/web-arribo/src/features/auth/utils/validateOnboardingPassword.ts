import {
  hasPasswordFormErrors,
  validatePassword,
  type PasswordFormErrors,
} from '@/features/auth/utils/validatePassword'

export type EstablecerPasswordFormErrors = PasswordFormErrors

export function validateOnboardingPassword(
  password: string,
  passwordConfirmation: string,
): EstablecerPasswordFormErrors {
  return validatePassword(password, passwordConfirmation)
}

export function hasOnboardingPasswordErrors(errors: EstablecerPasswordFormErrors) {
  return hasPasswordFormErrors(errors)
}

export { PASSWORD_POLICY_HINT } from '@/features/auth/utils/validatePassword'
