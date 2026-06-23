import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { createPortal } from 'react-dom'
import { Button, Checkbox, Input } from '@/components/ui'
import type { Producto, ProductoImpuesto, ProductoInput } from '@/features/productos/types/producto.types'
import {
  emptyProductoInput,
  productoToInput,
} from '@/features/productos/types/producto.types'

type ProductoFormModalProps =
  | {
      mode: 'create'
      producto?: null
      impuestosDisponibles: ProductoImpuesto[]
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: ProductoInput) => void | Promise<void>
    }
  | {
      mode: 'edit'
      producto: Producto | null
      impuestosDisponibles: ProductoImpuesto[]
      isOpen: boolean
      isLoading: boolean
      error: string | null
      onClose: () => void
      onSubmit: (values: ProductoInput) => void | Promise<void>
    }

export function ProductoFormModal(props: ProductoFormModalProps) {
  const { mode, impuestosDisponibles, isOpen, isLoading, error, onClose, onSubmit } = props
  const cancelRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const [values, setValues] = useState<ProductoInput>(emptyProductoInput())

  useEffect(() => {
    if (!isOpen) {
      return
    }

    if (mode === 'create') {
      setValues(emptyProductoInput())
      return
    }

    if (props.mode === 'edit' && props.producto) {
      setValues(productoToInput(props.producto))
    }
  }, [isOpen, mode, props])

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

  if (mode === 'edit' && !props.producto) {
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

  function toggleImpuesto(impuestoId: number, checked: boolean) {
    setValues((current) => {
      const ids = new Set(current.impuesto_ids)
      if (checked) {
        ids.add(impuestoId)
      } else {
        ids.delete(impuestoId)
      }

      return { ...current, impuesto_ids: Array.from(ids) }
    })
  }

  const titulo = mode === 'create' ? 'Nuevo producto' : 'Editar producto'

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
          {titulo}
        </h2>

        <form onSubmit={(event) => void handleSubmit(event)} className="producto-form">
          <Input
            label="Código"
            name="codigo"
            value={values.codigo}
            onChange={(event) => setValues((current) => ({ ...current, codigo: event.target.value }))}
            required
            disabled={isLoading}
          />

          <Input
            label="Nombre"
            name="nombre"
            value={values.nombre}
            onChange={(event) => setValues((current) => ({ ...current, nombre: event.target.value }))}
            required
            disabled={isLoading}
          />

          <Input
            label="Precio unitario"
            name="precio_unitario"
            type="number"
            min="0"
            step="1"
            value={values.precio_unitario}
            onChange={(event) =>
              setValues((current) => ({ ...current, precio_unitario: event.target.value }))
            }
            required
            disabled={isLoading}
          />

          <fieldset className="producto-form__impuestos">
            <legend>Impuestos</legend>
            <p className="producto-form__hint">
              Sin impuestos seleccionados el producto se trata como exento al emitir.
            </p>
            {impuestosDisponibles.length === 0 ? (
              <p className="page-empty">No hay impuestos configurados para el país de la empresa.</p>
            ) : (
              impuestosDisponibles.map((impuesto) => (
                <Checkbox
                  key={impuesto.id}
                  label={`${impuesto.nombre} (${impuesto.abreviacion})${
                    impuesto.tasa_vigente === null ? '' : ` — ${impuesto.tasa_vigente}%`
                  }`}
                  checked={values.impuesto_ids.includes(impuesto.id)}
                  onChange={(event) => toggleImpuesto(impuesto.id, event.target.checked)}
                  disabled={isLoading}
                />
              ))
            )}
          </fieldset>

          <Checkbox
            label="Activo"
            hint="Los productos inactivos no se pueden usar al emitir DTE."
            checked={values.activo}
            onChange={(event) => setValues((current) => ({ ...current, activo: event.target.checked }))}
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
            <Button type="submit" isLoading={isLoading}>
              {mode === 'create' ? 'Crear producto' : 'Guardar cambios'}
            </Button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
