import { Button } from '@/components/ui'
import type { EmisionLinea } from '@/features/emision/types/emision.types'
import { calcularLineaEmision } from '@/features/emision/utils/calcularTotalesEmision'
import type { Producto } from '@/features/productos/types/producto.types'
import { formatPrecioProducto } from '@/features/productos/types/producto.types'

interface EmisionLineasEditorProps {
  lineas: EmisionLinea[]
  productos: Producto[]
  disabled?: boolean
  onAdd: () => void
  onRemove: (key: string) => void
  onChange: (key: string, patch: Partial<EmisionLinea>) => void
}

export function EmisionLineasEditor({
  lineas,
  productos,
  disabled,
  onAdd,
  onRemove,
  onChange,
}: EmisionLineasEditorProps) {
  return (
    <div className="emision-wizard__lineas">
      <div className="emision-wizard__lineas-header">
        <h3>Ítems del documento</h3>
        <Button type="button" variant="secondary" disabled={disabled} onClick={onAdd}>
          Agregar ítem
        </Button>
      </div>

      {productos.length === 0 ? (
        <p className="emision-wizard__hint">
          No hay productos activos. Agregue productos al catálogo antes de emitir.
        </p>
      ) : null}

      <div className="emision-wizard__lineas-scroll">
        <table className="emision-wizard__lineas-table">
          <thead>
            <tr>
              <th className="emision-wizard__col-num" scope="col">
                #
              </th>
              <th className="emision-wizard__col-producto" scope="col">
                Producto
              </th>
              <th className="emision-wizard__col-cant" scope="col">
                Cant.
              </th>
              <th className="emision-wizard__col-desc" scope="col">
                Desc. %
              </th>
              <th className="emision-wizard__col-precio" scope="col">
                P. unit.
              </th>
              <th className="emision-wizard__col-neto" scope="col">
                Neto línea
              </th>
              <th className="emision-wizard__col-actions" scope="col" aria-label="Acciones" />
            </tr>
          </thead>
          <tbody>
            {lineas.map((linea, index) => {
              const producto = productos.find((item) => item.id === linea.producto_id)
              const cantidad = Number(linea.cantidad)
              const descuentoPct = Number(linea.descuento_pct)
              const lineaCalculada =
                producto &&
                Number.isFinite(cantidad) &&
                cantidad > 0 &&
                Number.isFinite(descuentoPct) &&
                descuentoPct >= 0 &&
                descuentoPct <= 100
                  ? calcularLineaEmision(producto, cantidad, descuentoPct)
                  : null

              return (
                <tr key={linea.key}>
                  <td className="emision-wizard__col-num">{index + 1}</td>
                  <td className="emision-wizard__col-producto">
                    <select
                      className="emision-wizard__linea-input"
                      value={linea.producto_id || ''}
                      disabled={disabled}
                      aria-label={`Producto ítem ${index + 1}`}
                      onChange={(event) =>
                        onChange(linea.key, { producto_id: Number(event.target.value) })
                      }
                    >
                      <option value="">Seleccione…</option>
                      {productos.map((item) => (
                        <option key={item.id} value={item.id}>
                          {item.codigo} — {item.nombre}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td className="emision-wizard__col-cant">
                    <input
                      className="emision-wizard__linea-input emision-wizard__linea-input--num"
                      type="number"
                      min="0.01"
                      step="any"
                      value={linea.cantidad}
                      disabled={disabled}
                      aria-label={`Cantidad ítem ${index + 1}`}
                      onChange={(event) => onChange(linea.key, { cantidad: event.target.value })}
                    />
                  </td>
                  <td className="emision-wizard__col-desc">
                    <input
                      className="emision-wizard__linea-input emision-wizard__linea-input--num"
                      type="number"
                      min="0"
                      max="100"
                      step="0.01"
                      value={linea.descuento_pct}
                      disabled={disabled}
                      aria-label={`Descuento ítem ${index + 1}`}
                      onChange={(event) =>
                        onChange(linea.key, { descuento_pct: event.target.value })
                      }
                    />
                  </td>
                  <td className="emision-wizard__col-precio emision-wizard__linea-readonly">
                    {producto ? formatPrecioProducto(producto.precio_unitario) : '—'}
                  </td>
                  <td className="emision-wizard__col-neto emision-wizard__linea-readonly">
                    {lineaCalculada ? formatPrecioProducto(lineaCalculada.neto) : '—'}
                  </td>
                  <td className="emision-wizard__col-actions">
                    {lineas.length > 1 ? (
                      <button
                        type="button"
                        className="emision-wizard__linea-remove"
                        disabled={disabled}
                        aria-label={`Quitar ítem ${index + 1}`}
                        onClick={() => onRemove(linea.key)}
                      >
                        Quitar
                      </button>
                    ) : null}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
