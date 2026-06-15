import { useEffect, useState, type FormEvent } from 'react'
import { Alert, Button, Input } from '@/components/ui'
import type { Empresa, EmpresaInput } from '@/features/empresas/types/empresa.types'
import {
  emptyEmpresaInput,
  empresaToInput,
} from '@/features/empresas/types/empresa.types'

interface EmpresaFormProps {
  initialValues?: EmpresaInput
  submitLabel: string
  isSubmitting: boolean
  onSubmit: (values: EmpresaInput) => Promise<void>
  onCancel: () => void
}

export function EmpresaForm({
  initialValues,
  submitLabel,
  isSubmitting,
  onSubmit,
  onCancel,
}: EmpresaFormProps) {
  const [values, setValues] = useState<EmpresaInput>(
    initialValues ?? emptyEmpresaInput(),
  )

  useEffect(() => {
    setValues(initialValues ?? emptyEmpresaInput())
  }, [initialValues])

  function updateField<K extends keyof EmpresaInput>(field: K, value: EmpresaInput[K]) {
    setValues((current) => ({ ...current, [field]: value }))
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    await onSubmit(values)
  }

  return (
    <form className="empresa-form" onSubmit={handleSubmit}>
      <div className="empresa-form__grid">
        <Input
          label="RUT"
          name="rut"
          value={values.rut}
          onChange={(event) => updateField('rut', event.target.value)}
          required
          maxLength={20}
        />
        <Input
          label="Razón social"
          name="razon_social"
          value={values.razon_social}
          onChange={(event) => updateField('razon_social', event.target.value)}
          required
          maxLength={250}
        />
        <Input
          label="Nombre fantasía"
          name="nombre_fantasia"
          value={values.nombre_fantasia}
          onChange={(event) => updateField('nombre_fantasia', event.target.value)}
          required
          maxLength={100}
        />
        <Input
          label="Giro"
          name="giro"
          value={values.giro}
          onChange={(event) => updateField('giro', event.target.value)}
          required
          maxLength={250}
        />
        <Input
          label="Dirección"
          name="direccion"
          value={values.direccion}
          onChange={(event) => updateField('direccion', event.target.value)}
          required
          maxLength={250}
        />
        <Input
          label="Resolución timbre"
          name="resolucion_timbre"
          value={values.resolucion_timbre}
          onChange={(event) => updateField('resolucion_timbre', event.target.value)}
          required
          maxLength={250}
        />
        <Input
          label="Fecha resolución"
          name="fecha_resolucion"
          type="date"
          value={values.fecha_resolucion}
          onChange={(event) => updateField('fecha_resolucion', event.target.value)}
          required
        />
        <Input
          label="Número resolución"
          name="numero_resolucion"
          type="number"
          value={values.numero_resolucion || ''}
          onChange={(event) =>
            updateField('numero_resolucion', Number(event.target.value))
          }
          required
          min={1}
        />
        <Input
          label="Teléfono 1"
          name="telefono1"
          value={values.telefono1 ?? ''}
          onChange={(event) => updateField('telefono1', event.target.value)}
          maxLength={20}
        />
        <Input
          label="Teléfono 2"
          name="telefono2"
          value={values.telefono2 ?? ''}
          onChange={(event) => updateField('telefono2', event.target.value)}
          maxLength={20}
        />
      </div>

      <div className="empresa-form__actions">
        <Button type="button" variant="secondary" onClick={onCancel}>
          Cancelar
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Guardando…' : submitLabel}
        </Button>
      </div>
    </form>
  )
}

interface EmpresaFormPanelProps {
  title: string
  empresa?: Empresa | null
  isSubmitting: boolean
  error?: string | null
  onSubmit: (values: EmpresaInput) => Promise<void>
  onCancel: () => void
}

export function EmpresaFormPanel({
  title,
  empresa,
  isSubmitting,
  error,
  onSubmit,
  onCancel,
}: EmpresaFormPanelProps) {
  return (
    <section className="panel-card">
      <h2>{title}</h2>
      {error ? <Alert variant="error">{error}</Alert> : null}
      <EmpresaForm
        initialValues={empresa ? empresaToInput(empresa) : emptyEmpresaInput()}
        submitLabel={empresa ? 'Actualizar empresa' : 'Crear empresa'}
        isSubmitting={isSubmitting}
        onSubmit={onSubmit}
        onCancel={onCancel}
      />
    </section>
  )
}
