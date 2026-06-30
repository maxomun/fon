export interface ProductoImpuesto {
  id: number
  abreviacion: string
  nombre: string
  tasa_vigente: number | null
}

export type ProductoAmbitoMonto = 'AFECTO' | 'EXENTO_NO_AFECTO' | 'NO_FACTURABLE' | null

export interface Producto {
  id: number
  empresa_id: number
  codigo: string
  nombre: string
  precio_unitario: string
  precio_con_impuestos: string
  activo: boolean
  ambito_monto: ProductoAmbitoMonto
  ambito_monto_efectivo: string
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
  ambito_monto: string
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
    ambito_monto: '',
  }
}

export const PRODUCTO_AMBITO_OPCIONES = [
  { value: '', label: 'Automático (según impuestos)' },
  { value: 'AFECTO', label: 'Afecto (con impuestos)' },
  { value: 'EXENTO_NO_AFECTO', label: 'Exento / no afecto' },
  { value: 'NO_FACTURABLE', label: 'No facturable' },
] as const

export function productoToInput(producto: Producto): ProductoInput {
  return {
    codigo: producto.codigo,
    nombre: producto.nombre,
    precio_unitario: producto.precio_unitario,
    activo: producto.activo,
    impuesto_ids: producto.impuestos.map((impuesto) => impuesto.id),
    ambito_monto: producto.ambito_monto ?? '',
  }
}

const PRODUCTO_CODIGO_MAX_LENGTH = 50
const PRODUCTO_NOMBRE_MAX_LENGTH = 250
const PRODUCTO_COPIA_SUFFIX = '_copia'

function truncarTexto(value: string, maxLength: number) {
  return value.length <= maxLength ? value : value.slice(0, maxLength)
}

export function codigoProductoCopia(codigo: string, codigosExistentes: Iterable<string>) {
  const existentes = new Set(codigosExistentes)
  const base = truncarTexto(
    `${codigo}${PRODUCTO_COPIA_SUFFIX}`,
    PRODUCTO_CODIGO_MAX_LENGTH,
  )

  if (!existentes.has(base)) {
    return base
  }

  for (let numero = 2; numero <= 99; numero += 1) {
    const sufijo = `${PRODUCTO_COPIA_SUFFIX}_${numero}`
    const prefijo = codigo.slice(0, PRODUCTO_CODIGO_MAX_LENGTH - sufijo.length)
    const candidato = `${prefijo}${sufijo}`

    if (!existentes.has(candidato)) {
      return candidato
    }
  }

  return truncarTexto(`${codigo}${PRODUCTO_COPIA_SUFFIX}`, PRODUCTO_CODIGO_MAX_LENGTH - 4) +
    `_${Date.now().toString().slice(-3)}`
}

export function nombreProductoCopia(nombre: string) {
  return truncarTexto(`${nombre}${PRODUCTO_COPIA_SUFFIX}`, PRODUCTO_NOMBRE_MAX_LENGTH)
}

export function productoDuplicadoInput(
  producto: Producto,
  codigosExistentes: Iterable<string>,
): ProductoInput {
  const base = productoToInput(producto)

  return {
    ...base,
    codigo: codigoProductoCopia(producto.codigo, codigosExistentes),
    nombre: nombreProductoCopia(producto.nombre),
    activo: true,
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
      ambito_monto: input.ambito_monto.trim() || null,
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
  if (producto.ambito_monto_efectivo === 'NO_FACTURABLE') {
    return 'No facturable'
  }

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
