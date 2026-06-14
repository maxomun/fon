import { useState, type FormEvent } from 'react'
import { Alert, Button, Input } from '@/components/ui'
import type { LoginCredentials } from '@/features/auth/types/auth.types'
import {
  hasLoginFormErrors,
  validateLoginForm,
  type LoginFormErrors,
} from '@/features/auth/utils/validateLogin'

interface LoginFormProps {
  onSubmit: (credentials: LoginCredentials) => void | Promise<void>
  isLoading?: boolean
  error?: string | null
}

const initialValues: LoginCredentials = {
  email: '',
  password: '',
}

export function LoginForm({ onSubmit, isLoading = false, error }: LoginFormProps) {
  const [values, setValues] = useState<LoginCredentials>(initialValues)
  const [fieldErrors, setFieldErrors] = useState<LoginFormErrors>({})

  function handleChange(field: keyof LoginCredentials, value: string) {
    setValues((current) => ({ ...current, [field]: value }))

    if (fieldErrors[field]) {
      setFieldErrors((current) => {
        const next = { ...current }
        delete next[field]
        return next
      })
    }
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const credentials: LoginCredentials = {
      email: values.email.trim(),
      password: values.password,
    }

    const errors = validateLoginForm(credentials)
    setFieldErrors(errors)

    if (hasLoginFormErrors(errors)) {
      return
    }

    await onSubmit(credentials)
  }

  return (
    <form className="login-form" onSubmit={handleSubmit} noValidate>
      {error ? <Alert variant="error">{error}</Alert> : null}

      <Input
        label="Email"
        name="email"
        type="email"
        autoComplete="email"
        placeholder="usuario@ejemplo.com"
        value={values.email}
        error={fieldErrors.email}
        disabled={isLoading}
        onChange={(event) => handleChange('email', event.target.value)}
      />

      <Input
        label="Contraseña"
        name="password"
        type="password"
        autoComplete="current-password"
        placeholder="••••••••"
        value={values.password}
        error={fieldErrors.password}
        disabled={isLoading}
        onChange={(event) => handleChange('password', event.target.value)}
      />

      <Button type="submit" isLoading={isLoading} className="login-form__submit">
        Iniciar sesión
      </Button>
    </form>
  )
}
