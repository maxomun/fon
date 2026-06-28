import {
  AUDITORIA_EMPRESA_SIN_ASIGNAR,
  CATEGORIA_OPCIONES,
  RESULTADO_OPCIONES,
  type AuditoriaFiltros,
} from '@/features/auditoria/types/auditEvent.types'
import type { Empresa } from '@/features/empresas/types/empresa.types'

interface AuditoriaFiltersProps {
  filtros: AuditoriaFiltros
  showEmpresaFilter?: boolean
  empresas?: Empresa[]
  isLoadingEmpresas?: boolean
  onChange: (partial: Partial<AuditoriaFiltros>) => void
}

function formatEmpresaOption(empresa: Empresa) {
  return `${empresa.razon_social} (${empresa.rut})`
}

export function AuditoriaFilters({
  filtros,
  showEmpresaFilter = false,
  empresas = [],
  isLoadingEmpresas = false,
  onChange,
}: AuditoriaFiltersProps) {
  const empresasOrdenadas = [...empresas].sort((a, b) =>
    a.razon_social.localeCompare(b.razon_social, 'es'),
  )

  return (
    <div className="page-toolbar">
      <label className="auditoria-filters__field page-toolbar__search">
        <span className="auditoria-filters__label">Buscar</span>
        <input
          type="search"
          className="select-input"
          name="q"
          placeholder="Acción, actor, recurso o mensaje…"
          value={filtros.q}
          onChange={(event) => onChange({ q: event.target.value })}
        />
      </label>

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
          <label className="auditoria-filters__field auditoria-filters__empresa">
            <span className="auditoria-filters__label">Empresa</span>
            <select
              className="select-input"
              value={filtros.empresa_id}
              disabled={isLoadingEmpresas}
              onChange={(event) => onChange({ empresa_id: event.target.value })}
            >
              <option value="">
                {isLoadingEmpresas ? 'Cargando empresas…' : 'Todas las empresas'}
              </option>
              <option value={AUDITORIA_EMPRESA_SIN_ASIGNAR}>Sin empresa</option>
              {empresasOrdenadas.map((empresa) => (
                <option key={empresa.id} value={String(empresa.id)}>
                  {formatEmpresaOption(empresa)}
                </option>
              ))}
            </select>
          </label>
        ) : null}
      </div>
    </div>
  )
}
