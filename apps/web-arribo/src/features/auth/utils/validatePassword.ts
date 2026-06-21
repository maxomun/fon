export const PASSWORD_POLICY_HINT =
  'Use al menos 8 caracteres, incluyendo mayúsculas, minúsculas y números.'

export type PasswordFormErrors = Partial<
  Record<'password' | 'password_confirmation', string>
>

export function validatePassword(
  password: string,
  passwordConfirmation: string,
): PasswordFormErrors {
  const errors: PasswordFormErrors = {}

  if (!password) {
    errors.password = 'La contraseña es requerida'
  } else {
    const normalized = password.trim()

    if (normalized !== password) {
      errors.password = 'La contraseña no debe tener espacios al inicio o al final'
    } else if (normalized.length < 8) {
      errors.password = 'La contraseña debe tener al menos 8 caracteres'
    } else if (!/[a-z]/.test(normalized)) {
      errors.password = 'La contraseña debe incluir al menos una letra minúscula'
    } else if (!/[A-Z]/.test(normalized)) {
      errors.password = 'La contraseña debe incluir al menos una letra mayúscula'
    } else if (!/\d/.test(normalized)) {
      errors.password = 'La contraseña debe incluir al menos un número'
    }
  }

  if (!passwordConfirmation) {
    errors.password_confirmation = 'Confirme la contraseña'
  } else if (password !== passwordConfirmation) {
    errors.password_confirmation = 'Las contraseñas no coinciden'
  }

  return errors
}

export function hasPasswordFormErrors(errors: PasswordFormErrors) {
  return Object.keys(errors).length > 0
}
