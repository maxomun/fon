import { useRef, useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { Alert, Button, Input } from '@/components/ui'
import { onboardingService } from '@/features/auth/services/onboardingService'
import {
  hasOnboardingPasswordErrors,
  PASSWORD_POLICY_HINT,
  validateOnboardingPassword,
} from '@/features/auth/utils/validateOnboardingPassword'
import type { EstablecerPasswordFormErrors } from '@/features/auth/types/onboarding.types'
import { ApiError } from '@/services/apiClient'

export function OnboardingEstablecerPasswordPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const token = searchParams.get('token')?.trim() ?? ''

  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [fieldErrors, setFieldErrors] = useState<EstablecerPasswordFormErrors>({})
  const [error, setError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isCompleted, setIsCompleted] = useState(false)
  const submitInFlight = useRef(false)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (!token) {
      setError('El enlace no incluye un token válido.')
      return
    }

    if (isSubmitting || submitInFlight.current) {
      return
    }

    const errors = validateOnboardingPassword(password, passwordConfirmation)
    setFieldErrors(errors)

    if (hasOnboardingPasswordErrors(errors)) {
      return
    }

    submitInFlight.current = true
    setIsSubmitting(true)
    setError(null)

    try {
      const response = await onboardingService.establecerPassword({
        token,
        password,
        password_confirmation: passwordConfirmation,
      })
      setSuccessMessage(response.message)
      setIsCompleted(true)
    } catch (err) {
      submitInFlight.current = false
      setError(
        err instanceof ApiError
          ? err.message
          : 'No se pudo establecer la contraseña.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  if (!token) {
    return (
      <AuthLayout title="Establecer contraseña" subtitle="Enlace de enrolamiento inválido">
        <Alert variant="error">
          El enlace no incluye un token válido. Complete primero la verificación de correo.
        </Alert>
        <p className="auth-footer-link">
          <Link to="/login">Volver al inicio de sesión</Link>
        </p>
      </AuthLayout>
    )
  }

  if (isCompleted) {
    return (
      <AuthLayout title="Cuenta lista" subtitle="Enrolamiento completado">
        <Alert variant="success">
          {successMessage ?? 'Contraseña establecida exitosamente. Ya puede iniciar sesión.'}
        </Alert>
        <Button onClick={() => navigate('/login')}>Ir al inicio de sesión</Button>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout title="Establecer contraseña" subtitle="Defina su clave de acceso a FacturaOn">
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
