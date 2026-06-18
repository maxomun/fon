import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button, Input } from '@/components/ui'
import type {
  Impuesto,
  ImpuestoInput,
  ImpuestoUpdateInput,
} from '@/features/impuestos/types/impuesto.types'
import {
  emptyImpuestoInput,
  impuestoToUpdateInput,
} from '@/features/impuestos/types/impuesto.types'

type ImpuestoFormModalProps =
  | {
      mode: 'create'
      impuesto?: null
      paisId: number
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: ImpuestoInput) => void | Promise<void>
    }
  | {
      mode: 'edit'
      impuesto: Impuesto | null
      paisId?: never
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: ImpuestoUpdateInput) => void | Promise<void>
    }

export function ImpuestoFormModal(props: ImpuestoFormModalProps) {
  const { mode, isOpen, isLoading, error, onClose, onSubmit } = props
  const cancelRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const [createValues, setCreateValues] = useState<ImpuestoInput>(emptyImpuestoInput())
  const [editValues, setEditValues] = useState<ImpuestoUpdateInput>({
    nombre: '',
    abreviacion: '',
  })

  useEffect(() => {
    if (mode === 'create' && isOpen && 'paisId' in props) {
      setCreateValues(emptyImpuestoInput(props.paisId))
    }
  }, [mode, isOpen, mode === 'create' ? props.paisId : null])

  useEffect(() => {
    if (mode === 'edit' && props.impuesto) {
      setEditValues(impuestoToUpdateInput(props.impuesto))
    }
  }, [mode, props.impuesto])

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

  if (mode === 'edit' && !props.impuesto) {
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

    await onSubmit(editValues)
  }

  const title =
    mode === 'create'
      ? 'Nuevo impuesto'
      : `Editar: ${props.impuesto?.abreviacion ?? ''}`

  const values = mode === 'create' ? createValues : editValues

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
              label="Nombre"
              name="nombre"
              value={values.nombre}
              onChange={(event) => {
                const nombre = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, nombre }))
                } else {
                  setEditValues((current) => ({ ...current, nombre }))
                }
              }}
              required
              maxLength={200}
              disabled={isLoading}
            />
            <Input
              label="Abreviación"
              name="abreviacion"
              value={values.abreviacion}
              onChange={(event) => {
                const abreviacion = event.target.value
                if (mode === 'create') {
                  setCreateValues((current) => ({ ...current, abreviacion }))
                } else {
                  setEditValues((current) => ({ ...current, abreviacion }))
                }
              }}
              required
              maxLength={50}
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
              {mode === 'create' ? 'Crear impuesto' : 'Guardar cambios'}
            </Button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
