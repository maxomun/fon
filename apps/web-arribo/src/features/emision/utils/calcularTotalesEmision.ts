import type {
  EmisionCalcularTotalesData,
  EmisionCalcularTotalesRequest,
  EmisionDescuentoRecargoGlobal,
  EmisionDescuentoRecargoGlobalRequest,
  EmisionLinea,
  EmisionReceptor,
  EmisionTipoValorGlobal,
  EmisionTotales,
  EmisionLineaCalculada,
} from '@/features/emision/types/emision.types'
import { FACTURA_ELECTRONICA_CODIGO } from '@/features/emision/types/emision.types'
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
    neto_no_facturable: 0,
    iva,
    tasa_iva: tasaIva,
    total: netoAfecto + netoExento + iva,
    origen: 'local',
  }
}

export function mapearTotalesDesdeApi(
  totales: EmisionCalcularTotalesData['totales'],
): EmisionTotales {
  return {
    neto_afecto: totales.neto_afecto,
    neto_exento: totales.neto_exento,
    neto_no_facturable: totales.neto_no_facturable ?? 0,
    iva: totales.iva,
    tasa_iva: totales.tasa_iva,
    total: totales.total,
    origen: 'servidor',
  }
}

export function parseGlobalMovimiento(
  movimiento: EmisionDescuentoRecargoGlobal,
): EmisionDescuentoRecargoGlobalRequest | null {
  const valor = Number(movimiento.valor)
  if (!Number.isFinite(valor) || valor <= 0) {
    return null
  }

  if (movimiento.tipo_valor === 'PORCENTAJE' && valor > 100) {
    return null
  }

  const payload: EmisionDescuentoRecargoGlobalRequest = {
    tipo_movimiento: movimiento.tipo_movimiento,
    tipo_valor: movimiento.tipo_valor,
    valor,
    aplica_sobre: movimiento.aplica_sobre,
  }

  const glosa = movimiento.glosa.trim()
  if (glosa) {
    payload.glosa = glosa
  }

  return payload
}

export function serializarGlobalesParaApi(
  globales: EmisionDescuentoRecargoGlobal[],
): EmisionDescuentoRecargoGlobalRequest[] {
  return globales.flatMap((movimiento) => {
    const parsed = parseGlobalMovimiento(movimiento)
    return parsed ? [parsed] : []
  })
}

export function buildCalcularTotalesRequest(
  empresaId: number,
  lineas: EmisionLinea[],
  receptor: EmisionReceptor,
  globales: EmisionDescuentoRecargoGlobal[],
): EmisionCalcularTotalesRequest {
  const globalesApi = serializarGlobalesParaApi(globales)

  return {
    empresa_id: empresaId,
    tipo_documento: Number(FACTURA_ELECTRONICA_CODIGO),
    receptor: {
      rut: receptor.rut.trim() || '00000000-0',
      razon_social: receptor.razon_social.trim() || 'Preview',
      giro: receptor.giro.trim() || 'Sin giro',
      direccion: receptor.direccion.trim() || 'Sin dirección',
      email: receptor.email.trim(),
    },
    items: lineas.map((linea) => ({
      producto_id: linea.producto_id,
      cantidad: Number(linea.cantidad),
      descuento_pct: Number(linea.descuento_pct) || 0,
    })),
    ...(globalesApi.length > 0 ? { descuentos_recargos_globales: globalesApi } : {}),
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

export function labelTipoValorGlobal(tipo: EmisionTipoValorGlobal) {
  return tipo === 'PORCENTAJE' ? '%' : '$'
}
