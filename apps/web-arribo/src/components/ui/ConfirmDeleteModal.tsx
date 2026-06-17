import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'

const DEFAULT_CONFIRM_WORD = 'eliminar'

interface ConfirmDeleteModalProps {
  isOpen: boolean
  title: string
  itemName: string
  description?: string
  confirmWord?: string
  isDeleting?: boolean
  error?: string | null
  onConfirm: () => void | Promise<void>
  onCancel: () => void
}

export function ConfirmDeleteModal({
  isOpen,
  title,
  itemName,
  description,
  confirmWord = DEFAULT_CONFIRM_WORD,
  isDeleting = false,
  error,
  onConfirm,
  onCancel,
}: ConfirmDeleteModalProps) {
  const [confirmation, setConfirmation] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const titleId = useId()
  const descriptionId = useId()

  const isConfirmed =
    confirmation.trim().toLowerCase() === confirmWord.toLowerCase()

  useEffect(() => {
    if (!isOpen) {
      setConfirmation('')
      return
    }

    inputRef.current?.focus()

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape' && !isDeleting) {
        onCancel()
      }
    }

    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [isOpen, isDeleting, onCancel])

  if (!isOpen) {
    return null
  }

  function handleBackdropClick() {
    if (!isDeleting) {
      onCancel()
    }
  }

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (isConfirmed && !isDeleting) {
      void onConfirm()
    }
  }

  return createPortal(
    <div className="modal-overlay" onClick={handleBackdropClick}>
      <div
        className="modal-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descriptionId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId} className="modal-dialog__title">
          {title}
        </h2>

        <div id={descriptionId} className="modal-dialog__description">
          <p>
            ¿Está seguro de eliminar <strong>{itemName}</strong>? Esta acción no se
            puede deshacer.
          </p>
          {description ? <p>{description}</p> : null}
        </div>

        {error ? <p className="modal-dialog__error">{error}</p> : null}

        <form onSubmit={handleSubmit}>
          <Input
            ref={inputRef}
            label={`Escriba ${confirmWord} para confirmar`}
            name="confirm-delete"
            value={confirmation}
            onChange={(event) => setConfirmation(event.target.value)}
            autoComplete="off"
            disabled={isDeleting}
          />

          <div className="modal-dialog__actions">
            <Button
              type="button"
              variant="secondary"
              onClick={onCancel}
              disabled={isDeleting}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              className="btn-danger"
              disabled={!isConfirmed || isDeleting}
              isLoading={isDeleting}
            >
              Eliminar
            </Button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
