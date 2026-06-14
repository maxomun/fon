import { useState } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { LoadingScreen } from '@/components/ui'
import { LoginForm } from '@/features/auth/components/LoginForm'
import { useAuth } from '@/features/auth/hooks/useAuth'
import type { LoginCredentials } from '@/features/auth/types/auth.types'
import { ApiError } from '@/services/apiClient'

export function LoginPage() {
  const { login, isAuthenticated, isLoading } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

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

    try {
      await login(credentials)
      navigate(redirectTo, { replace: true })
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('No se pudo iniciar sesión. Intenta nuevamente.')
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <AuthLayout title="Arribo" subtitle="Inicia sesión para continuar">
      <LoginForm
        onSubmit={handleLogin}
        isLoading={isSubmitting}
        error={error}
      />
    </AuthLayout>
  )
}
