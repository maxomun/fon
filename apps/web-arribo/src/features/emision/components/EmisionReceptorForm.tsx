import { Input } from '@/components/ui'
import type { EmisionReceptor } from '@/features/emision/types/emision.types'

interface EmisionReceptorFormProps {
  value: EmisionReceptor
  disabled?: boolean
  onChange: (value: EmisionReceptor) => void
}

export function EmisionReceptorForm({ value, disabled, onChange }: EmisionReceptorFormProps) {
  function updateField<K extends keyof EmisionReceptor>(field: K, fieldValue: string) {
    onChange({ ...value, [field]: fieldValue })
  }

  return (
    <div className="emision-wizard__grid">
      <Input
        label="RUT"
        name="receptor_rut"
        value={value.rut}
        disabled={disabled}
        placeholder="12.345.678-9"
        onChange={(event) => updateField('rut', event.target.value)}
      />
      <Input
        label="Razón social"
        name="receptor_razon_social"
        value={value.razon_social}
        disabled={disabled}
        onChange={(event) => updateField('razon_social', event.target.value)}
      />
      <Input
        label="Giro"
        name="receptor_giro"
        value={value.giro}
        disabled={disabled}
        onChange={(event) => updateField('giro', event.target.value)}
      />
      <Input
        label="Dirección"
        name="receptor_direccion"
        value={value.direccion}
        disabled={disabled}
        onChange={(event) => updateField('direccion', event.target.value)}
      />
      <Input
        label="Email (opcional)"
        name="receptor_email"
        type="email"
        value={value.email}
        disabled={disabled}
        onChange={(event) => updateField('email', event.target.value)}
      />
    </div>
  )
}
