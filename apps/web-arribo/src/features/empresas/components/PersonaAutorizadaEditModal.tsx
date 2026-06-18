import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button, Input } from '@/components/ui'
import {
  ESTADO_PERSONA_ACTIVA,
  ESTADO_PERSONA_INACTIVA,
  emptyPersonaAutorizadaInput,
  personaAutorizadaToInput,
  type PersonaAutorizada,
  type PersonaAutorizadaInput,
} from '@/features/empresas/types/personaAutorizada.types'

interface PersonaAutorizadaEditModalProps {
  persona: PersonaAutorizada | null
  isOpen: boolean
  isLoading: boolean
  error: string | null
  onClose: () => void
  onSubmit: (values: PersonaAutorizadaInput) => void | Promise<void>
}

export function PersonaAutorizadaEditModal({
  persona,
  isOpen,
  isLoading,
  error,
  onClose,
  onSubmit,
}: PersonaAutorizadaEditModalProps) {
  const cancelRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const [values, setValues] = useState<PersonaAutorizadaInput>(emptyPersonaAutorizadaInput())

  useEffect(() => {
    if (persona) {
      setValues(personaAutorizadaToInput(persona))
    }
  }, [persona])

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

  if (!isOpen || !persona) {
    return null
  }

  function handleBackdropClick() {
    if (!isLoading) {
      onClose()
    }
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    await onSubmit(values)
  }

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
          Editar: {persona.nombre_completo}
        </h2>

        <form className="empresa-form" onSubmit={handleSubmit}>
          <div className="empresa-form__grid">
            <Input
              label="RUT"
              name="rut"
              value={values.rut}
              onChange={(event) =>
                setValues((current) => ({ ...current, rut: event.target.value }))
              }
              required
              maxLength={20}
              disabled={isLoading}
            />
            <Input
              label="Nombres"
              name="nombres"
              value={values.nombres}
              onChange={(event) =>
                setValues((current) => ({ ...current, nombres: event.target.value }))
              }
              required
              disabled={isLoading}
            />
            <Input
              label="Apellido paterno"
              name="apellido_paterno"
              value={values.apellido_paterno}
              onChange={(event) =>
                setValues((current) => ({
                  ...current,
                  apellido_paterno: event.target.value,
                }))
              }
              disabled={isLoading}
            />
            <Input
              label="Apellido materno"
              name="apellido_materno"
              value={values.apellido_materno}
              onChange={(event) =>
                setValues((current) => ({
                  ...current,
                  apellido_materno: event.target.value,
                }))
              }
              disabled={isLoading}
            />
            <Input
              label="Email"
              name="email"
              type="email"
              value={values.email}
              onChange={(event) =>
                setValues((current) => ({ ...current, email: event.target.value }))
              }
              required
              disabled={isLoading}
            />
            <Input
              label="Orden de prioridad"
              name="orden"
              type="number"
              min={1}
              value={values.orden ?? 1}
              onChange={(event) =>
                setValues((current) => ({
                  ...current,
                  orden: Number(event.target.value),
                }))
              }
              required
              disabled={isLoading}
            />
            <div className="field">
              <label htmlFor="persona-estado">Estado</label>
              <select
                id="persona-estado"
                className="select-input"
                value={values.estado ?? ESTADO_PERSONA_ACTIVA}
                onChange={(event) =>
                  setValues((current) => ({
                    ...current,
                    estado: Number(event.target.value),
                  }))
                }
                disabled={isLoading}
                required
              >
                <option value={ESTADO_PERSONA_ACTIVA}>Activa</option>
                <option value={ESTADO_PERSONA_INACTIVA}>Inactiva</option>
              </select>
            </div>
          </div>

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
              Guardar cambios
            </Button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
