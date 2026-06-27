import type { EmisionLinea, EmisionReceptor } from '@/features/emision/types/emision.types'

export function validarReceptor(receptor: EmisionReceptor): string[] {
  const errores: string[] = []

  if (!receptor.rut.trim()) {
    errores.push('El RUT del receptor es obligatorio.')
  }
  if (!receptor.razon_social.trim()) {
    errores.push('La razón social del receptor es obligatoria.')
  }
  if (!receptor.giro.trim()) {
    errores.push('El giro del receptor es obligatorio.')
  }
  if (!receptor.direccion.trim()) {
    errores.push('La dirección del receptor es obligatoria.')
  }

  return errores
}

export function validarLineas(lineas: EmisionLinea[]): string[] {
  const errores: string[] = []

  if (lineas.length === 0) {
    errores.push('Debe agregar al menos un ítem.')
    return errores
  }

  lineas.forEach((linea, index) => {
    const n = index + 1

    if (!linea.producto_id) {
      errores.push(`Ítem ${n}: seleccione un producto.`)
    }

    const cantidad = Number(linea.cantidad)
    if (!Number.isFinite(cantidad) || cantidad <= 0) {
      errores.push(`Ítem ${n}: la cantidad debe ser mayor a cero.`)
    }

    const descuento = Number(linea.descuento_pct)
    if (!Number.isFinite(descuento) || descuento < 0 || descuento > 100) {
      errores.push(`Ítem ${n}: el descuento debe estar entre 0 y 100.`)
    }
  })

  return errores
}
