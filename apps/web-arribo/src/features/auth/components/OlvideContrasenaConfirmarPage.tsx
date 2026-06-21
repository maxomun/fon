import { useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { Alert, Button, Input } from '@/components/ui'
import { authService } from '@/features/auth/services/authService'
import {
  hasPasswordFormErrors,
  PASSWORD_POLICY_HINT,
  validatePassword,
} from '@/features/auth/utils/validatePassword'
import type { PasswordFormErrors } from '@/features/auth/utils/validatePassword'
import { ApiError } from '@/services/apiClient'

export function OlvideContrasenaConfirmarPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const token = searchParams.get('token')?.trim() ?? ''

  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [fieldErrors, setFieldErrors] = useState<PasswordFormErrors>({})
  const [error, setError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isCompleted, setIsCompleted] = useState(false)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (!token) {
      setError('El enlace no incluye un token válido.')
      return
    }

    const errors = validatePassword(password, passwordConfirmation)
    setFieldErrors(errors)

    if (hasPasswordFormErrors(errors)) {
      return
    }

    setIsSubmitting(true)
    setError(null)

    try {
      const response = await authService.restablecerPassword({
        token,
        password,
        password_confirmation: passwordConfirmation,
      })
      setSuccessMessage(response.message)
      setIsCompleted(true)
    } catch (err) {
      setError(
        err instanceof ApiError
          ? err.message
          : 'No se pudo restablecer la contraseña.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  if (!token) {
    return (
      <AuthLayout title="Restablecer contraseña" subtitle="Enlace inválido">
        <Alert variant="error">
          El enlace no incluye un token válido. Solicite uno nuevo desde la pantalla
          de recuperación.
        </Alert>
        <p className="auth-footer-link">
          <Link to="/olvide-contrasena">Solicitar nuevo enlace</Link>
        </p>
      </AuthLayout>
    )
  }

  if (isCompleted) {
    return (
      <AuthLayout title="Contraseña actualizada" subtitle="Ya puede iniciar sesión">
        <Alert variant="success">
          {successMessage ?? 'Contraseña restablecida exitosamente.'}
        </Alert>
        <Button onClick={() => navigate('/login')}>Ir al inicio de sesión</Button>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout title="Restablecer contraseña" subtitle="Defina su nueva clave de acceso">
      <form className="login-form" onSubmit={handleSubmit} noValidate>
        {error ? <Alert variant="error">{error}</Alert> : null}

        <p className="auth-footer-text">{PASSWORD_POLICY_HINT}</p>

        <Input
          label="Nueva contraseña"
          name="password"
          type="password"
          autoComplete="new-password"
          value={password}
          error={fieldErrors.password}
          disabled={isSubmitting}
          onChange={(event) => setPassword(event.target.value)}
          required
        />

        <Input
          label="Confirmar contraseña"
          name="password_confirmation"
          type="password"
          autoComplete="new-password"
          value={passwordConfirmation}
          error={fieldErrors.password_confirmation}
          disabled={isSubmitting}
          onChange={(event) => setPasswordConfirmation(event.target.value)}
          required
        />

        <Button type="submit" isLoading={isSubmitting} className="login-form__submit">
          Guardar contraseña
        </Button>
      </form>

      <p className="auth-footer-link">
        <Link to="/login">Volver al inicio de sesión</Link>
      </p>
    </AuthLayout>
  )
}
