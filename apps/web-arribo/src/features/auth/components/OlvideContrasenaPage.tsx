import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { AuthLayout } from '@/components/layout/AuthLayout'
import { Alert, Button, Input } from '@/components/ui'
import { authService } from '@/features/auth/services/authService'
import { isPasswordResetOnboardingCode } from '@/features/auth/types/auth.types'
import { ApiError } from '@/services/apiClient'

export function OlvideContrasenaPage() {
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [infoMessage, setInfoMessage] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const normalizedEmail = email.trim()
    if (!normalizedEmail) {
      setError('Ingrese su correo electrónico.')
      setInfoMessage(null)
      setSuccessMessage(null)
      return
    }

    setIsSubmitting(true)
    setError(null)
    setInfoMessage(null)
    setSuccessMessage(null)

    try {
      const response = await authService.solicitarRestablecimientoPassword(normalizedEmail)

      if (isPasswordResetOnboardingCode(response.code)) {
        setInfoMessage(response.message)
        return
      }

      if (response.data?.enviado === false) {
        setInfoMessage(response.message)
        return
      }

      setSuccessMessage(response.message)
    } catch (err) {
      setError(
        err instanceof ApiError
          ? err.message
          : 'No se pudo procesar la solicitud. Intente nuevamente.',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <AuthLayout
      title="Olvidé mi contraseña"
      subtitle="Le enviaremos un enlace para definir una nueva contraseña"
    >
      <form className="login-form" onSubmit={handleSubmit} noValidate>
        {error ? <Alert variant="error">{error}</Alert> : null}
        {infoMessage ? <Alert variant="info">{infoMessage}</Alert> : null}
        {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}

        <Input
          label="Email"
          name="email"
          type="email"
          autoComplete="email"
          placeholder="usuario@ejemplo.com"
          value={email}
          disabled={isSubmitting}
          onChange={(event) => setEmail(event.target.value)}
          required
        />

        <Button type="submit" isLoading={isSubmitting} className="login-form__submit">
          Enviar enlace
        </Button>
      </form>

      <p className="auth-footer-link">
        <Link to="/login">Volver al inicio de sesión</Link>
      </p>
    </AuthLayout>
  )
}
