import { authenticatedClient } from '@/services/authenticatedClient'
import type {
  ImpuestosDisponiblesResponse,
  Producto,
  ProductoActivoFiltro,
  ProductoDeleteResponse,
  ProductoInput,
  ProductoResponse,
  ProductosListResponse,
} from '@/features/productos/types/producto.types'
import { productoDuplicadoInput, productoPayload } from '@/features/productos/types/producto.types'

function baseUrl(empresaId: number) {
  return `/api/v1/empresas/${empresaId}/productos`
}

function listQuery(query = '', activo: ProductoActivoFiltro = 'todos', page = 1) {
  const params = new URLSearchParams()
  params.set('page', String(page))
  params.set('per_page', '100')

  if (query.trim()) {
    params.set('q', query.trim())
  }

  if (activo === 'activos') {
    params.set('activo', 'true')
  } else if (activo === 'inactivos') {
    params.set('activo', 'false')
  }

  return `?${params.toString()}`
}

export const productosService = {
  list(empresaId: number, query = '', activo: ProductoActivoFiltro = 'todos', page = 1) {
    return authenticatedClient.get<ProductosListResponse>(
      `${baseUrl(empresaId)}${listQuery(query, activo, page)}`,
    )
  },

  get(empresaId: number, productoId: number) {
    return authenticatedClient.get<ProductoResponse>(`${baseUrl(empresaId)}/${productoId}`)
  },

  impuestosDisponibles(empresaId: number) {
    return authenticatedClient.get<ImpuestosDisponiblesResponse>(
      `${baseUrl(empresaId)}/impuestos_disponibles`,
    )
  },

  create(empresaId: number, input: ProductoInput) {
    return authenticatedClient.post<ProductoResponse>(baseUrl(empresaId), productoPayload(input))
  },

  duplicate(empresaId: number, producto: Producto, codigosExistentes: Iterable<string>) {
    return this.create(empresaId, productoDuplicadoInput(producto, codigosExistentes))
  },

  update(empresaId: number, productoId: number, input: ProductoInput) {
    return authenticatedClient.patch<ProductoResponse>(
      `${baseUrl(empresaId)}/${productoId}`,
      productoPayload(input),
    )
  },

  remove(empresaId: number, productoId: number) {
    return authenticatedClient.delete<ProductoDeleteResponse>(
      `${baseUrl(empresaId)}/${productoId}`,
    )
  },
}
