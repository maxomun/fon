import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button, Input } from '@/components/ui'
import type {
  TipoHabilitado,
  TipoHabilitadoUpdateInput,
} from '@/features/empresas/types/tipoHabilitado.types'
import { tipoHabilitadoToUpdateInput } from '@/features/empresas/types/tipoHabilitado.types'

interface TipoHabilitadoEditModalProps {
  tipo: TipoHabilitado | null
  isOpen: boolean
  isLoading: boolean
  error: string | null
  onClose: () => void
  onSubmit: (values: TipoHabilitadoUpdateInput) => void | Promise<void>
}

export function TipoHabilitadoEditModal({
  tipo,
  isOpen,
  isLoading,
  error,
  onClose,
  onSubmit,
}: TipoHabilitadoEditModalProps) {
  const cancelRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const [values, setValues] = useState<TipoHabilitadoUpdateInput>({
    fecha_habilitacion: '',
  })

  useEffect(() => {
    if (tipo) {
      setValues(tipoHabilitadoToUpdateInput(tipo))
    }
  }, [tipo])

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

  if (!isOpen || !tipo) {
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
          Editar habilitación: {tipo.tipo_documento.codigo} —{' '}
          {tipo.tipo_documento.nombre}
        </h2>

        <form className="empresa-form" onSubmit={handleSubmit}>
          <div className="empresa-form__grid">
            <Input
              label="Fecha habilitación"
              name="fecha_habilitacion"
              type="datetime-local"
              value={values.fecha_habilitacion}
              onChange={(event) =>
                setValues({ fecha_habilitacion: event.target.value })
              }
              required
              disabled={isLoading}
            />
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
