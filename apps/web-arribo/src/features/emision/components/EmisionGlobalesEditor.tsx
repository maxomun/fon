import { Button } from '@/components/ui'
import type {
  EmisionDescuentoRecargoGlobal,
  EmisionMovimientoGlobalCalculado,
} from '@/features/emision/types/emision.types'
import {
  EMISION_GLOBAL_APLICA_SOBRE_OPCIONES,
  EMISION_GLOBAL_TIPO_MOV_OPCIONES,
  EMISION_GLOBAL_TIPO_VALOR_OPCIONES,
  MAX_MOVIMIENTOS_GLOBALES,
} from '@/features/emision/types/emision.types'
import { formatPrecioProducto } from '@/features/productos/types/producto.types'

interface EmisionGlobalesEditorProps {
  globales: EmisionDescuentoRecargoGlobal[]
  movimientosCalculados: EmisionMovimientoGlobalCalculado[]
  disabled?: boolean
  onAdd: () => void
  onRemove: (key: string) => void
  onChange: (key: string, patch: Partial<EmisionDescuentoRecargoGlobal>) => void
}

export function EmisionGlobalesEditor({
  globales,
  movimientosCalculados,
  disabled,
  onAdd,
  onRemove,
  onChange,
}: EmisionGlobalesEditorProps) {
  const montosPorOrden = new Map(
    movimientosCalculados.map((movimiento) => [movimiento.orden, movimiento.monto_calculado]),
  )

  return (
    <div className="emision-wizard__globales">
      <div className="emision-wizard__lineas-header">
        <div>
          <h3>Descuentos / recargos globales</h3>
          <p className="emision-wizard__hint emision-wizard__hint--inline">
            Opcional. Se aplican sobre el documento y se reflejan en el XML como{' '}
            <code>DscRcgGlobal</code>.
          </p>
        </div>
        <Button
          type="button"
          variant="secondary"
          disabled={disabled || globales.length >= MAX_MOVIMIENTOS_GLOBALES}
          onClick={onAdd}
        >
          Agregar movimiento
        </Button>
      </div>

      {globales.length === 0 ? (
        <p className="emision-wizard__hint">
          Sin movimientos globales. Use el botón para agregar descuentos o recargos sobre neto
          afecto, exento o no facturable.
        </p>
      ) : (
        <div className="emision-wizard__lineas-scroll">
          <table className="emision-wizard__lineas-table emision-wizard__globales-table">
            <thead>
              <tr>
                <th className="emision-wizard__col-num" scope="col">
                  #
                </th>
                <th scope="col">Tipo</th>
                <th scope="col">Glosa</th>
                <th className="emision-wizard__col-tipo-valor" scope="col">
                  Formato
                </th>
                <th className="emision-wizard__col-valor-global" scope="col">
                  Valor
                </th>
                <th scope="col">Aplica sobre</th>
                <th className="emision-wizard__col-monto-global" scope="col">
                  Monto calc.
                </th>
                <th className="emision-wizard__col-actions" scope="col" aria-label="Acciones" />
              </tr>
            </thead>
            <tbody>
              {globales.map((movimiento, index) => {
                const montoCalculado = montosPorOrden.get(index + 1)

                return (
                  <tr key={movimiento.key}>
                    <td className="emision-wizard__col-num">{index + 1}</td>
                    <td>
                      <select
                        className="emision-wizard__linea-input"
                        value={movimiento.tipo_movimiento}
                        disabled={disabled}
                        aria-label={`Tipo movimiento global ${index + 1}`}
                        onChange={(event) =>
                          onChange(movimiento.key, {
                            tipo_movimiento: event.target.value as EmisionDescuentoRecargoGlobal['tipo_movimiento'],
                          })
                        }
                      >
                        {EMISION_GLOBAL_TIPO_MOV_OPCIONES.map((opcion) => (
                          <option key={opcion.value} value={opcion.value}>
                            {opcion.label}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td>
                      <input
                        className="emision-wizard__linea-input"
                        type="text"
                        maxLength={250}
                        placeholder="Descuento comercial"
                        value={movimiento.glosa}
                        disabled={disabled}
                        aria-label={`Glosa movimiento global ${index + 1}`}
                        onChange={(event) =>
                          onChange(movimiento.key, { glosa: event.target.value })
                        }
                      />
                    </td>
                    <td className="emision-wizard__col-tipo-valor">
                      <select
                        className="emision-wizard__linea-input emision-wizard__linea-input--num"
                        value={movimiento.tipo_valor}
                        disabled={disabled}
                        aria-label={`Formato movimiento global ${index + 1}`}
                        onChange={(event) =>
                          onChange(movimiento.key, {
                            tipo_valor: event.target.value as EmisionDescuentoRecargoGlobal['tipo_valor'],
                          })
                        }
                      >
                        {EMISION_GLOBAL_TIPO_VALOR_OPCIONES.map((opcion) => (
                          <option key={opcion.value} value={opcion.value}>
                            {opcion.label}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td className="emision-wizard__col-valor-global">
                      <input
                        className="emision-wizard__linea-input emision-wizard__linea-input--num"
                        type="number"
                        min="0"
                        step="any"
                        value={movimiento.valor}
                        disabled={disabled}
                        aria-label={`Valor movimiento global ${index + 1}`}
                        onChange={(event) =>
                          onChange(movimiento.key, { valor: event.target.value })
                        }
                      />
                    </td>
                    <td>
                      <select
                        className="emision-wizard__linea-input"
                        value={movimiento.aplica_sobre}
                        disabled={disabled}
                        aria-label={`Ámbito movimiento global ${index + 1}`}
                        onChange={(event) =>
                          onChange(movimiento.key, {
                            aplica_sobre: event.target.value as EmisionDescuentoRecargoGlobal['aplica_sobre'],
                          })
                        }
                      >
                        {EMISION_GLOBAL_APLICA_SOBRE_OPCIONES.map((opcion) => (
                          <option key={opcion.value} value={opcion.value}>
                            {opcion.label}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td className="emision-wizard__col-monto-global emision-wizard__linea-readonly">
                      {montoCalculado != null ? formatPrecioProducto(montoCalculado) : '—'}
                    </td>
                    <td className="emision-wizard__col-actions">
                      <button
                        type="button"
                        className="emision-wizard__linea-remove"
                        disabled={disabled}
                        aria-label={`Quitar movimiento global ${index + 1}`}
                        onClick={() => onRemove(movimiento.key)}
                      >
                        Quitar
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
