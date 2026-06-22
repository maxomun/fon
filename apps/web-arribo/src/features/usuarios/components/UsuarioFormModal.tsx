import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button, Checkbox, Input } from '@/components/ui'
import type {
  Usuario,
  UsuarioCreateInput,
  UsuarioUpdateInput,
} from '@/features/usuarios/types/usuario.types'
import {
  emptyUsuarioCreateInput,
  usuarioToUpdateInput,
} from '@/features/usuarios/types/usuario.types'

type UsuarioFormModalProps =
  | {
      mode: 'create'
      usuario?: null
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: UsuarioCreateInput) => void | Promise<void>
    }
  | {
      mode: 'edit'
      usuario: Usuario | null
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: UsuarioUpdateInput) => void | Promise<void>
    }

export function UsuarioFormModal(props: UsuarioFormModalProps) {
  const { mode, isOpen, isLoading, error, onClose, onSubmit } = props
  const cancelRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const [createValues, setCreateValues] = useState<UsuarioCreateInput>(emptyUsuarioCreateInput())
  const [editValues, setEditValues] = useState<UsuarioUpdateInput>({
    email: '',
    nombres: '',
    administrador_fon: true,
  })
  const [changePassword, setChangePassword] = useState(false)

  useEffect(() => {
    if (mode === 'create' && isOpen) {
      setCreateValues(emptyUsuarioCreateInput())
    }
  }, [mode, isOpen])

  useEffect(() => {
    if (mode === 'edit' && props.usuario) {
      setEditValues(usuarioToUpdateInput(props.usuario))
      setChangePassword(false)
    }
  }, [mode, props.usuario])

  useEffect(() => {
    if (!isOpen) {
      return
    }

    cancelRef.current?.focus()

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape' && !isLoading) {
        onClose()
      }
    }

    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [isOpen, isLoading, onClose])

  if (!isOpen) {
    return null
  }

  if (mode === 'edit' && !props.usuario) {
    return null
  }

  function handleBackdropClick() {
    if (!isLoading) {
      onClose()
    }
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (mode === 'create') {
      await onSubmit(createValues)
      return
    }

    const payload = { ...editValues }
    if (!changePassword) {
      delete payload.password
      delete payload.password_confirmation
    }

    await onSubmit(payload)
  }

  const title =
    mode === 'create'
      ? 'Nuevo operador de plataforma'
      : `Editar: ${props.usuario?.nombre_completo ?? props.usuario?.email ?? ''}`

  const createPasswordFilled = Boolean(createValues.password?.trim())
  const showEnviarAcceso = mode === 'create' && !createPasswordFilled

  return createPortal(
    <div className="modal-overlay" onClick={handleBackdropClick}>
      <div
        className="modal-dialog modal-dialog--form"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId} className="modal-dialog__title">
          {title}
        </h2>

        <form className="empresa-form" onSubmit={handleSubmit}>
          <div className="empresa-form__grid">
            <Input
              label="Email"
              name="email"
              type="email"
              autoComplete="email"
              value={mode === 'create' ? createValues.email : (editValues.email ?? '')}
              onChange={(event) => {
                const email = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, email }))
                } else {
                  setEditValues((current) => ({ ...current, email }))
                }
              }}
              required
              disabled={isLoading}
            />
            <Input
              label="Username"
              name="username"
              value={mode === 'create' ? (createValues.username ?? '') : (editValues.username ?? '')}
              onChange={(event) => {
                const username = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, username }))
                } else {
                  setEditValues((current) => ({ ...current, username }))
                }
              }}
              disabled={isLoading}
            />
            <p className="field-checkbox__hint">Opcional; si no se indica, se genera desde el email.</p>
            <Input
              label="Nombres"
              name="nombres"
              value={mode === 'create' ? createValues.nombres : (editValues.nombres ?? '')}
              onChange={(event) => {
                const nombres = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, nombres }))
                } else {
                  setEditValues((current) => ({ ...current, nombres }))
                }
              }}
              required
              disabled={isLoading}
            />
            <Input
              label="Apellido paterno"
              name="apellido_paterno"
              value={
                mode === 'create'
                  ? (createValues.apellido_paterno ?? '')
                  : (editValues.apellido_paterno ?? '')
              }
              onChange={(event) => {
                const apellido_paterno = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, apellido_paterno }))
                } else {
                  setEditValues((current) => ({ ...current, apellido_paterno }))
                }
              }}
              disabled={isLoading}
            />
            <Input
              label="Apellido materno"
              name="apellido_materno"
              value={
                mode === 'create'
                  ? (createValues.apellido_materno ?? '')
                  : (editValues.apellido_materno ?? '')
              }
              onChange={(event) => {
                const apellido_materno = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, apellido_materno }))
                } else {
                  setEditValues((current) => ({ ...current, apellido_materno }))
                }
              }}
              disabled={isLoading}
            />
          </div>

          {mode === 'create' ? (
            <>
              <div className="empresa-form__grid">
                <Input
                  label="Contraseña"
                  name="password"
                  type="password"
                  autoComplete="new-password"
                  value={createValues.password ?? ''}
                  onChange={(event) =>
                    setCreateValues((current) => ({
                      ...current,
                      password: event.target.value,
                      enviar_acceso: event.target.value ? false : current.enviar_acceso,
                    }))
                  }
                  disabled={isLoading}
                />
                <Input
                  label="Confirmar contraseña"
                  name="password_confirmation"
                  type="password"
                  autoComplete="new-password"
                  value={createValues.password_confirmation ?? ''}
                  onChange={(event) =>
                    setCreateValues((current) => ({
                      ...current,
                      password_confirmation: event.target.value,
                    }))
                  }
                  disabled={isLoading || !createPasswordFilled}
                />
              </div>
              <p className="field-checkbox__hint">
                Deje la contraseña vacía y marque &quot;Enviar acceso por correo&quot; para generar
                una temporal automáticamente.
              </p>
              {showEnviarAcceso ? (
                <Checkbox
                  label="Enviar acceso por correo"
                  hint="Se generará una contraseña temporal y se enviará al email indicado"
                  checked={createValues.enviar_acceso ?? false}
                  onChange={(event) =>
                    setCreateValues((current) => ({
                      ...current,
                      enviar_acceso: event.target.checked,
                    }))
                  }
                  disabled={isLoading}
                />
              ) : null}
            </>
          ) : (
            <>
              <Checkbox
                label="Cambiar contraseña"
                checked={changePassword}
                onChange={(event) => setChangePassword(event.target.checked)}
                disabled={isLoading}
              />
              {changePassword ? (
                <div className="empresa-form__grid">
                  <Input
                    label="Nueva contraseña"
                    name="password"
                    type="password"
                    autoComplete="new-password"
                    value={editValues.password ?? ''}
                    onChange={(event) =>
                      setEditValues((current) => ({
                        ...current,
                        password: event.target.value,
                      }))
                    }
                    required
                    disabled={isLoading}
                  />
                  <Input
                    label="Confirmar contraseña"
                    name="password_confirmation"
                    type="password"
                    autoComplete="new-password"
                    value={editValues.password_confirmation ?? ''}
                    onChange={(event) =>
                      setEditValues((current) => ({
                        ...current,
                        password_confirmation: event.target.value,
                      }))
                    }
                    required
                    disabled={isLoading}
                  />
                </div>
              ) : null}
            </>
          )}

          <Checkbox
            label="Administrador FON"
            hint="Acceso global a la plataforma"
            checked={
              mode === 'create'
                ? (createValues.administrador_fon ?? true)
                : (editValues.administrador_fon ?? false)
            }
            onChange={(event) => {
              const administrador_fon = event.target.checked
              if (mode === 'create') {
                setCreateValues((current) => ({ ...current, administrador_fon }))
              } else {
                setEditValues((current) => ({ ...current, administrador_fon }))
              }
            }}
            disabled={isLoading}
          />

          {error ? <p className="modal-dialog__error">{error}</p> : null}

          <div className="modal-dialog__actions">
            <Button
              ref={cancelRef}
              type="button"
              variant="secondary"
              onClick={onClose}
              disabled={isLoading}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={isLoading} isLoading={isLoading}>
              {mode === 'create' ? 'Crear operador' : 'Guardar cambios'}
            </Button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
