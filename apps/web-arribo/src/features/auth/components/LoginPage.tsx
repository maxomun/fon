import { useState } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { Alert, Button, LoadingScreen } from '@/components/ui'
import { LoginForm } from '@/features/auth/components/LoginForm'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { authService } from '@/features/auth/services/authService'
import type { LoginCredentials } from '@/features/auth/types/auth.types'
import { ApiError } from '@/services/apiClient'

export function LoginPage() {
  const { login, isAuthenticated, isLoading } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [onboardingCode, setOnboardingCode] = useState<string | null>(null)
  const [pendingEmail, setPendingEmail] = useState('')
  const [resendMessage, setResendMessage] = useState<string | null>(null)
  const [isResending, setIsResending] = useState(false)

  const redirectTo =
    (location.state as { from?: string } | null)?.from ?? '/dashboard'

  if (isLoading) {
    return <LoadingScreen message="Verificando sesión…" />
  }

  if (isAuthenticated) {
    return <Navigate to={redirectTo} replace />
  }

  async function handleLogin(credentials: LoginCredentials) {
    setIsSubmitting(true)
    setError(null)
    setOnboardingCode(null)
    setResendMessage(null)

    try {
      await login(credentials)
      navigate(redirectTo, { replace: true })
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
        setOnboardingCode(err.code ?? null)
        if (err.code === 'EMAIL_NOT_VERIFIED') {
          setPendingEmail(credentials.email)
        }
      } else {
        setError('No se pudo iniciar sesión. Intenta nuevamente.')
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleResendVerification() {
    if (!pendingEmail.trim()) {
      return
    }

    setIsResending(true)
    setResendMessage(null)

    try {
      const response = await authService.reenviarVerificacion(pendingEmail.trim())
      setResendMessage(response.message)
    } catch (err) {
      setResendMessage(
        err instanceof ApiError
          ? err.message
          : 'No se pudo reenviar el correo de verificación.',
      )
    } finally {
      setIsResending(false)
    }
  }

  return (
    <AuthLayout title="Arribo" subtitle="Inicia sesión para continuar">
      <LoginForm
        onSubmit={handleLogin}
        isLoading={isSubmitting}
        error={error}
      />

      {onboardingCode === 'EMAIL_NOT_VERIFIED' ? (
        <div className="login-form__onboarding">
          <p className="login-form__onboarding-text">
            Revise su bandeja de entrada y spam. Si no encuentra el correo, puede
            solicitar uno nuevo.
          </p>
          <Button
            type="button"
            variant="secondary"
            isLoading={isResending}
            onClick={() => void handleResendVerification()}
          >
            Reenviar correo de verificación
          </Button>
          {resendMessage ? <Alert variant="success">{resendMessage}</Alert> : null}
        </div>
      ) : null}

      {onboardingCode === 'ONBOARDING_INCOMPLETE' ? (
        <Alert variant="info">
          Debe completar el enrolamiento usando los enlaces enviados a su correo
          electrónico.
        </Alert>
      ) : null}
    </AuthLayout>
  )
}
