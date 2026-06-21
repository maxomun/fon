import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { Alert, Button } from '@/components/ui'
import { onboardingService } from '@/features/auth/services/onboardingService'
import { ApiError } from '@/services/apiClient'

type PageState = 'loading' | 'success' | 'error' | 'missing-token'

export function OnboardingVerificarEmailPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const token = searchParams.get('token')?.trim() ?? ''

  const [state, setState] = useState<PageState>(token ? 'loading' : 'missing-token')
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  useEffect(() => {
    if (!token) {
      return
    }

    let cancelled = false

    async function verify() {
      setState('loading')
      setError(null)

      try {
        const response = await onboardingService.verificarEmail(token)
        if (cancelled) {
          return
        }

        setMessage(response.message)
        setState('success')

        window.setTimeout(() => {
          navigate(
            `/onboarding/establecer-password?token=${encodeURIComponent(response.data.setup_token)}`,
            { replace: true },
          )
        }, 1200)
      } catch (err) {
        if (cancelled) {
          return
        }

        setState('error')
        setError(
          err instanceof ApiError
            ? err.message
            : 'No se pudo verificar el correo electrónico.',
        )
      }
    }

    void verify()

    return () => {
      cancelled = true
    }
  }, [token, navigate])

  if (state === 'missing-token') {
    return (
      <AuthLayout title="Verificar correo" subtitle="Enlace de enrolamiento inválido">
        <Alert variant="error">
          El enlace no incluye un token válido. Solicite un nuevo correo de verificación.
        </Alert>
        <p className="auth-footer-link">
          <Link to="/login">Volver al inicio de sesión</Link>
        </p>
      </AuthLayout>
    )
  }

  if (state === 'loading') {
    return (
      <AuthLayout title="Verificar correo" subtitle="Confirmando su dirección de email">
        <p className="placeholder">Verificando correo…</p>
      </AuthLayout>
    )
  }

  if (state === 'success') {
    return (
      <AuthLayout title="Correo verificado" subtitle="Redirigiendo al siguiente paso">
        <Alert variant="success">{message ?? 'Correo verificado exitosamente.'}</Alert>
        <p className="auth-footer-text">A continuación podrá establecer su contraseña.</p>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout title="Verificar correo" subtitle="No se pudo completar la verificación">
      <Alert variant="error">{error}</Alert>
      <p className="auth-footer-text">
        El enlace puede haber expirado o ya fue utilizado. Puede solicitar uno nuevo desde el
        inicio de sesión.
      </p>
      <Button variant="secondary" onClick={() => navigate('/login')}>
        Ir al inicio de sesión
      </Button>
    </AuthLayout>
  )
}
