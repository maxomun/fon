import { Input } from '@/components/ui'
import {
  CATEGORIA_OPCIONES,
  RESULTADO_OPCIONES,
  type AuditoriaFiltros,
} from '@/features/auditoria/types/auditEvent.types'

interface AuditoriaFiltersProps {
  filtros: AuditoriaFiltros
  showEmpresaFilter?: boolean
  onChange: (partial: Partial<AuditoriaFiltros>) => void
}

export function AuditoriaFilters({
  filtros,
  showEmpresaFilter = false,
  onChange,
}: AuditoriaFiltersProps) {
  return (
    <div className="page-toolbar">
      <Input
        label="Buscar"
        name="q"
        placeholder="Acción, actor, recurso o mensaje…"
        value={filtros.q}
        onChange={(event) => onChange({ q: event.target.value })}
        className="page-toolbar__search"
      />

      <div className="page-toolbar__filters auditoria-filters">
        <label className="auditoria-filters__field">
          <span className="auditoria-filters__label">Categoría</span>
          <select
            className="select-input"
            value={filtros.categoria}
            onChange={(event) => onChange({ categoria: event.target.value })}
          >
            {CATEGORIA_OPCIONES.map((opcion) => (
              <option key={opcion.value || 'todas'} value={opcion.value}>
                {opcion.label}
              </option>
            ))}
          </select>
        </label>

        <label className="auditoria-filters__field">
          <span className="auditoria-filters__label">Resultado</span>
          <select
            className="select-input"
            value={filtros.resultado}
            onChange={(event) =>
              onChange({ resultado: event.target.value as AuditoriaFiltros['resultado'] })
            }
          >
            {RESULTADO_OPCIONES.map((opcion) => (
              <option key={opcion.value || 'todos'} value={opcion.value}>
                {opcion.label}
              </option>
            ))}
          </select>
        </label>

        <label className="auditoria-filters__field">
          <span className="auditoria-filters__label">Desde</span>
          <input
            type="date"
            className="select-input"
            value={filtros.desde}
            onChange={(event) => onChange({ desde: event.target.value })}
          />
        </label>

        <label className="auditoria-filters__field">
          <span className="auditoria-filters__label">Hasta</span>
          <input
            type="date"
            className="select-input"
            value={filtros.hasta}
            onChange={(event) => onChange({ hasta: event.target.value })}
          />
        </label>

        {showEmpresaFilter ? (
          <Input
            label="Empresa ID"
            name="empresa_id"
            placeholder="Filtrar por ID…"
            value={filtros.empresa_id}
            onChange={(event) => onChange({ empresa_id: event.target.value })}
            className="auditoria-filters__empresa-id"
          />
        ) : null}
      </div>
    </div>
  )
}
