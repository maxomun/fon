import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { Alert, Button } from '@/components/ui'
import { onboardingService } from '@/features/auth/services/onboardingService'
import {
  beginVerifySession,
  cacheSetupToken,
  failVerifySession,
  readCachedSetupToken,
  redirectToSetupPassword,
  waitForCachedSetupToken,
} from '@/features/auth/utils/onboardingVerifySession'
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

    const cachedSetupToken = readCachedSetupToken(token)
    if (cachedSetupToken) {
      redirectToSetupPassword(cachedSetupToken, navigate)
      return
    }

    const verifyState = beginVerifySession(token)

    if (verifyState === 'done') {
      const setupToken = readCachedSetupToken(token)
      if (setupToken) {
        redirectToSetupPassword(setupToken, navigate)
      }
      return
    }

    if (verifyState === 'pending') {
      return waitForCachedSetupToken(token, (setupToken) => {
        redirectToSetupPassword(setupToken, navigate)
      })
    }

    let cancelled = false

    async function verify() {
      setState('loading')
      setError(null)

      try {
        const response = await onboardingService.verificarEmail(token)
        const setupToken = response.data?.setup_token?.trim()

        if (!setupToken) {
          failVerifySession(token)
          if (cancelled) {
            return
          }

          setState('error')
          setError(
            'El correo se verificó, pero no se recibió el enlace para establecer la contraseña. ' +
              'Solicite un nuevo correo de enrolamiento.',
          )
          return
        }

        cacheSetupToken(token, setupToken)

        if (cancelled) {
          return
        }

        setMessage(response.message)
        setState('success')

        window.setTimeout(() => {
          redirectToSetupPassword(setupToken, navigate)
        }, 1200)
      } catch (err) {
        failVerifySession(token)

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
        <p className="text-muted-foreground mt-5 text-center text-sm">
          <Link
            to="/login"
            className="text-primary font-medium underline-offset-4 hover:underline"
          >
            Volver al inicio de sesión
          </Link>
        </p>
      </AuthLayout>
    )
  }

  if (state === 'loading') {
    return (
      <AuthLayout title="Verificar correo" subtitle="Confirmando su dirección de email">
        <p className="text-muted-foreground text-sm">Verificando correo…</p>
      </AuthLayout>
    )
  }

  if (state === 'success') {
    return (
      <AuthLayout title="Correo verificado" subtitle="Redirigiendo al siguiente paso">
        <Alert variant="success">{message ?? 'Correo verificado exitosamente.'}</Alert>
        <p className="text-muted-foreground mt-4 text-sm">
          A continuación podrá establecer su contraseña.
        </p>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout title="Verificar correo" subtitle="No se pudo completar la verificación">
      <Alert variant="error">{error}</Alert>
      <p className="text-muted-foreground mt-4 text-sm leading-relaxed">
        El enlace puede haber expirado o ya fue utilizado. Puede solicitar uno nuevo desde el
        inicio de sesión.
      </p>
      <Button variant="secondary" className="mt-5" onClick={() => navigate('/login')}>
        Ir al inicio de sesión
      </Button>
    </AuthLayout>
  )
}
