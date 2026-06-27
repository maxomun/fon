import type {
  EmisionLinea,
  EmisionLineaCalculada,
  EmisionTotales,
} from '@/features/emision/types/emision.types'
import type { Producto } from '@/features/productos/types/producto.types'

export function calcularLineaEmision(
  producto: Producto,
  cantidad: number,
  descuentoPct: number,
): EmisionLineaCalculada {
  const precio = Number(producto.precio_unitario)
  const subtotal = cantidad * precio
  const descuentoMonto = descuentoPct > 0 ? subtotal * (descuentoPct / 100) : 0
  const neto = Math.round(subtotal - descuentoMonto)

  return {
    producto,
    cantidad,
    descuento_pct: descuentoPct,
    subtotal,
    descuento_monto: descuentoMonto,
    neto,
    afecto: producto.afecto,
  }
}

export function calcularTotalesEmision(
  lineas: EmisionLineaCalculada[],
): EmisionTotales {
  let netoAfecto = 0
  let netoExento = 0
  let iva = 0
  let tasaIva = 0

  for (const linea of lineas) {
    if (linea.afecto) {
      netoAfecto += linea.neto

      const ivaImpuesto = linea.producto.impuestos.find((imp) => imp.abreviacion === 'IVA')
      if (ivaImpuesto?.tasa_vigente) {
        tasaIva = ivaImpuesto.tasa_vigente
        iva += Math.round((linea.neto * ivaImpuesto.tasa_vigente) / 100)
      }
    } else {
      netoExento += linea.neto
    }
  }

  return {
    neto_afecto: netoAfecto,
    neto_exento: netoExento,
    iva,
    tasa_iva: tasaIva,
    total: netoAfecto + netoExento + iva,
  }
}

export function resolverLineasCalculadas(
  lineas: EmisionLinea[],
  productos: Producto[],
): EmisionLineaCalculada[] {
  const porId = new Map(productos.map((producto) => [producto.id, producto]))

  return lineas
    .map((linea) => {
      const producto = porId.get(linea.producto_id)
      if (!producto) {
        return null
      }

      const cantidad = Number(linea.cantidad)
      const descuentoPct = Number(linea.descuento_pct)

      if (!Number.isFinite(cantidad) || cantidad <= 0) {
        return null
      }

      if (!Number.isFinite(descuentoPct) || descuentoPct < 0 || descuentoPct > 100) {
        return null
      }

      return calcularLineaEmision(producto, cantidad, descuentoPct)
    })
    .filter((linea): linea is EmisionLineaCalculada => linea !== null)
}
