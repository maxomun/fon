export interface ProductoImpuesto {
  id: number
  abreviacion: string
  nombre: string
  tasa_vigente: number | null
}

export interface Producto {
  id: number
  empresa_id: number
  codigo: string
  nombre: string
  precio_unitario: string
  precio_con_impuestos: string
  activo: boolean
  afecto: boolean
  impuestos: ProductoImpuesto[]
  tiene_ventas: boolean
  fecha_creacion: string
  fecha_actualizacion: string
}

export interface ProductoInput {
  codigo: string
  nombre: string
  precio_unitario: string
  activo: boolean
  impuesto_ids: number[]
}

export type ProductoActivoFiltro = 'todos' | 'activos' | 'inactivos'

export interface ProductosListMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

export interface ProductosListResponse {
  success: boolean
  data: Producto[]
  meta: ProductosListMeta
}

export interface ProductoResponse {
  success: boolean
  data: Producto
  message?: string
}

export interface ProductoDeleteResponse {
  success: boolean
  message?: string
}

export interface ImpuestosDisponiblesResponse {
  success: boolean
  data: ProductoImpuesto[]
}

export function emptyProductoInput(): ProductoInput {
  return {
    codigo: '',
    nombre: '',
    precio_unitario: '',
    activo: true,
    impuesto_ids: [],
  }
}

export function productoToInput(producto: Producto): ProductoInput {
  return {
    codigo: producto.codigo,
    nombre: producto.nombre,
    precio_unitario: producto.precio_unitario,
    activo: producto.activo,
    impuesto_ids: producto.impuestos.map((impuesto) => impuesto.id),
  }
}

export function productoPayload(input: ProductoInput) {
  return {
    producto: {
      codigo: input.codigo.trim(),
      nombre: input.nombre.trim(),
      precio_unitario: Number(input.precio_unitario),
      activo: input.activo,
      impuesto_ids: input.impuesto_ids,
    },
  }
}

export function calcularPrecioConImpuestos(
  precioUnitario: string | number,
  impuestos: ProductoImpuesto[],
) {
  const neto = typeof precioUnitario === 'string' ? Number(precioUnitario) : precioUnitario
  if (!Number.isFinite(neto)) {
    return null
  }

  if (impuestos.length === 0) {
    return neto
  }

  const totalImpuestos = impuestos.reduce((acumulado, impuesto) => {
    const tasa = impuesto.tasa_vigente ?? 0
    return acumulado + neto * (tasa / 100)
  }, 0)

  return Math.round(neto + totalImpuestos)
}

export function precioConImpuestosProducto(producto: Producto) {
  if (producto.precio_con_impuestos !== undefined) {
    return producto.precio_con_impuestos
  }

  return calcularPrecioConImpuestos(producto.precio_unitario, producto.impuestos)
}

export function formatPrecioProducto(value: string | number | null | undefined) {
  if (value === null || value === undefined) {
    return '—'
  }

  const numero = typeof value === 'string' ? Number(value) : value
  if (!Number.isFinite(numero)) {
    return '—'
  }

  return numero.toLocaleString('es-CL', {
    style: 'currency',
    currency: 'CLP',
    maximumFractionDigits: 0,
  })
}

export function impuestosProductoLabel(producto: Producto) {
  if (producto.impuestos.length === 0) {
    return 'Exento'
  }

  return producto.impuestos
    .map((impuesto) => {
      const tasa =
        impuesto.tasa_vigente === null ? '—' : `${impuesto.tasa_vigente}%`
      return `${impuesto.abreviacion} (${tasa})`
    })
    .join(', ')
}
