import { useEffect, useState, type FormEvent } from 'react'
import { Alert, Button, Input } from '@/components/ui'
import type { Empresa, EmpresaInput } from '@/features/empresas/types/empresa.types'
import {
  emptyEmpresaInput,
  empresaToInput,
} from '@/features/empresas/types/empresa.types'
import { paisesService } from '@/features/empresas/services/paisesService'
import type { Pais } from '@/features/empresas/types/pais.types'
import { findPaisChile } from '@/features/empresas/types/pais.types'

interface EmpresaFormProps {
  paises: Pais[]
  isLoadingPaises: boolean
  initialValues?: EmpresaInput
  submitLabel: string
  isSubmitting: boolean
  onSubmit: (values: EmpresaInput) => Promise<void>
  onCancel: () => void
}

export function EmpresaForm({
  paises,
  isLoadingPaises,
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

  const isFormDisabled = isSubmitting || isLoadingPaises || paises.length === 0

  return (
    <form className="empresa-form" onSubmit={handleSubmit}>
      <div className="empresa-form__grid">
        <div className="field">
          <label htmlFor="empresa-pais">País</label>
          <select
            id="empresa-pais"
            className="select-input"
            value={values.pais_id || ''}
            onChange={(event) => updateField('pais_id', Number(event.target.value))}
            required
            disabled={isFormDisabled}
          >
            <option value="" disabled>
              {isLoadingPaises ? 'Cargando países…' : 'Seleccione un país'}
            </option>
            {paises.map((pais) => (
              <option key={pais.id} value={pais.id}>
                {pais.nombre} ({pais.codigo})
              </option>
            ))}
          </select>
        </div>
        <Input
          label="RUT"
          name="rut"
          value={values.rut}
          onChange={(event) => updateField('rut', event.target.value)}
          required
          maxLength={20}
          disabled={isFormDisabled}
        />
        <Input
          label="Razón social"
          name="razon_social"
          value={values.razon_social}
          onChange={(event) => updateField('razon_social', event.target.value)}
          required
          maxLength={250}
          disabled={isFormDisabled}
        />
        <Input
          label="Nombre fantasía"
          name="nombre_fantasia"
          value={values.nombre_fantasia}
          onChange={(event) => updateField('nombre_fantasia', event.target.value)}
          required
          maxLength={100}
          disabled={isFormDisabled}
        />
        <Input
          label="Giro"
          name="giro"
          value={values.giro}
          onChange={(event) => updateField('giro', event.target.value)}
          required
          maxLength={250}
          disabled={isFormDisabled}
        />
        <Input
          label="Dirección"
          name="direccion"
          value={values.direccion}
          onChange={(event) => updateField('direccion', event.target.value)}
          required
          maxLength={250}
          disabled={isFormDisabled}
        />
        <Input
          label="Resolución timbre"
          name="resolucion_timbre"
          value={values.resolucion_timbre}
          onChange={(event) => updateField('resolucion_timbre', event.target.value)}
          required
          maxLength={250}
          disabled={isFormDisabled}
        />
        <Input
          label="Fecha resolución"
          name="fecha_resolucion"
          type="date"
          value={values.fecha_resolucion}
          onChange={(event) => updateField('fecha_resolucion', event.target.value)}
          required
          disabled={isFormDisabled}
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
          disabled={isFormDisabled}
        />
        <Input
          label="Teléfono 1"
          name="telefono1"
          value={values.telefono1 ?? ''}
          onChange={(event) => updateField('telefono1', event.target.value)}
          maxLength={20}
          disabled={isFormDisabled}
        />
        <Input
          label="Teléfono 2"
          name="telefono2"
          value={values.telefono2 ?? ''}
          onChange={(event) => updateField('telefono2', event.target.value)}
          maxLength={20}
          disabled={isFormDisabled}
        />
      </div>

      <div className="empresa-form__actions">
        <Button type="button" variant="secondary" onClick={onCancel}>
          Cancelar
        </Button>
        <Button type="submit" disabled={isFormDisabled}>
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
  const [paises, setPaises] = useState<Pais[]>([])
  const [isLoadingPaises, setIsLoadingPaises] = useState(true)
  const [paisesError, setPaisesError] = useState<string | null>(null)
  const [defaultInput, setDefaultInput] = useState<EmpresaInput | undefined>(
    empresa ? empresaToInput(empresa) : undefined,
  )

  useEffect(() => {
    let cancelled = false

    async function loadPaises() {
      setIsLoadingPaises(true)
      setPaisesError(null)

      try {
        const response = await paisesService.list()
        if (cancelled) {
          return
        }

        setPaises(response.data)

        if (empresa) {
          setDefaultInput(empresaToInput(empresa))
        } else {
          const paisChile = findPaisChile(response.data)
          setDefaultInput(emptyEmpresaInput(paisChile?.id ?? response.data[0]?.id ?? 0))
        }
      } catch {
        if (!cancelled) {
          setPaisesError('No se pudieron cargar los países')
        }
      } finally {
        if (!cancelled) {
          setIsLoadingPaises(false)
        }
      }
    }

    void loadPaises()

    return () => {
      cancelled = true
    }
  }, [empresa])

  return (
    <section className="panel-card">
      <h2>{title}</h2>
      {error ? <Alert variant="error">{error}</Alert> : null}
      {paisesError ? <Alert variant="error">{paisesError}</Alert> : null}
      {!isLoadingPaises && paises.length === 0 && !paisesError ? (
        <Alert variant="error">
          No hay países habilitados. Configure al menos un país antes de crear empresas.
        </Alert>
      ) : null}
      <EmpresaForm
        paises={paises}
        isLoadingPaises={isLoadingPaises}
        initialValues={defaultInput}
        submitLabel={empresa ? 'Actualizar empresa' : 'Crear empresa'}
        isSubmitting={isSubmitting}
        onSubmit={onSubmit}
        onCancel={onCancel}
      />
    </section>
  )
}
