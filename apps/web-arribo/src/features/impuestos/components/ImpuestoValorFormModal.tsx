import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button, Input } from '@/components/ui'
import type { ImpuestoValor, ImpuestoValorInput } from '@/features/impuestos/types/impuestoValor.types'
import {
  emptyImpuestoValorInput,
  impuestoValorToInput,
} from '@/features/impuestos/types/impuestoValor.types'

type ImpuestoValorFormModalProps =
  | {
      mode: 'create'
      valor?: null
      impuestoLabel: string
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: ImpuestoValorInput) => void | Promise<void>
    }
  | {
      mode: 'edit'
      valor: ImpuestoValor | null
      impuestoLabel: string
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: ImpuestoValorInput) => void | Promise<void>
    }

export function ImpuestoValorFormModal(props: ImpuestoValorFormModalProps) {
  const { mode, impuestoLabel, isOpen, isLoading, error, onClose, onSubmit } = props
  const cancelRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const [values, setValues] = useState<ImpuestoValorInput>(emptyImpuestoValorInput())

  useEffect(() => {
    if (!isOpen) {
      return
    }

    if (mode === 'create') {
      setValues(emptyImpuestoValorInput())
      return
    }

    if (mode === 'edit' && 'valor' in props && props.valor) {
      setValues(impuestoValorToInput(props.valor))
    }
  }, [isOpen, mode, mode === 'edit' && 'valor' in props ? props.valor : null])

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

  if (mode === 'edit' && !props.valor) {
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

  const title =
    mode === 'create'
      ? `Nuevo valor — ${impuestoLabel}`
      : `Editar valor — ${impuestoLabel}`

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
              label="Valor (%)"
              name="valor"
              type="number"
              min={0}
              max={100}
              step={0.01}
              value={values.valor}
              onChange={(event) =>
                setValues((current) => ({
                  ...current,
                  valor: Number(event.target.value),
                }))
              }
              required
              disabled={isLoading}
            />
            <Input
              label="Fecha activación"
              name="fecha_activacion"
              type="datetime-local"
              value={values.fecha_activacion}
              onChange={(event) =>
                setValues((current) => ({
                  ...current,
                  fecha_activacion: event.target.value,
                }))
              }
              required
              disabled={isLoading}
            />
            <Input
              label="Fecha caducación (opcional)"
              name="fecha_caducacion"
              type="datetime-local"
              value={values.fecha_caducacion ?? ''}
              onChange={(event) =>
                setValues((current) => ({
                  ...current,
                  fecha_caducacion: event.target.value || null,
                }))
              }
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
              {mode === 'create' ? 'Registrar valor' : 'Guardar cambios'}
            </Button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
