import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDeleteModal, Input } from '@/components/ui'
import { ProductoFormModal } from '@/features/productos/components/ProductoFormModal'
import { ProductoRowActions } from '@/features/productos/components/ProductoRowActions'
import { productosService } from '@/features/productos/services/productosService'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import type {
  Producto,
  ProductoActivoFiltro,
  ProductoImpuesto,
  ProductoInput,
} from '@/features/productos/types/producto.types'
import {
  formatPrecioProducto,
  impuestosProductoLabel,
  precioConImpuestosProducto,
} from '@/features/productos/types/producto.types'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { canAdministrarEmpresa } from '@/features/auth/utils/roles'
import { ApiError } from '@/services/apiClient'

type FormMode = 'create' | 'edit' | null

const ACTIVO_OPCIONES: { value: ProductoActivoFiltro; label: string }[] = [
  { value: 'todos', label: 'Todos' },
  { value: 'activos', label: 'Activos' },
  { value: 'inactivos', label: 'Inactivos' },
]

export function EmpresaProductosPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)
  const { user } = useAuth()
  const canEdit = canAdministrarEmpresa(user, empresaId)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [productos, setProductos] = useState<Producto[]>([])
  const [impuestosDisponibles, setImpuestosDisponibles] = useState<ProductoImpuesto[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [activoFiltro, setActivoFiltro] = useState<ProductoActivoFiltro>('activos')

  const [isLoading, setIsLoading] = useState(true)
  const [pageError, setPageError] = useState<string | null>(null)
  const [listError, setListError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const [formMode, setFormMode] = useState<FormMode>(null)
  const [selectedProducto, setSelectedProducto] = useState<Producto | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const [productoToDelete, setProductoToDelete] = useState<Producto | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      setPageError('Empresa no válida')
      setIsLoading(false)
      return
    }

    setPageError(null)
    setListError(null)
    setIsLoading(true)

    try {
      const [empresaResponse, productosResponse, impuestosResponse] = await Promise.all([
        empresasService.get(empresaId),
        productosService.list(empresaId, searchQuery, activoFiltro),
        productosService.impuestosDisponibles(empresaId),
      ])

      setEmpresa(empresaResponse.data)
      setProductos(productosResponse.data)
      setImpuestosDisponibles(impuestosResponse.data)
    } catch (error) {
      setListError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar los productos',
      )
    } finally {
      setIsLoading(false)
    }
  }, [activoFiltro, empresaId, searchQuery])

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadData()
    }, 300)

    return () => window.clearTimeout(timeout)
  }, [loadData])

  function openCreateModal() {
    setSelectedProducto(null)
    setFormError(null)
    setFormMode('create')
  }

  function openEditModal(producto: Producto) {
    setSelectedProducto(producto)
    setFormError(null)
    setFormMode('edit')
  }

  function closeFormModal() {
    setFormMode(null)
    setSelectedProducto(null)
    setFormError(null)
  }

  async function handleCreate(values: ProductoInput) {
    setIsSubmitting(true)
    setFormError(null)

    try {
      const response = await productosService.create(empresaId, values)
      setSuccessMessage(response.message ?? 'Producto creado exitosamente')
      closeFormModal()
      await loadData()
    } catch (error) {
      setFormError(error instanceof ApiError ? error.message : 'No se pudo crear el producto')
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleUpdate(values: ProductoInput) {
    if (!selectedProducto) {
      return
    }

    setIsSubmitting(true)
    setFormError(null)

    try {
      const response = await productosService.update(empresaId, selectedProducto.id, values)
      setSuccessMessage(response.message ?? 'Producto actualizado exitosamente')
      closeFormModal()
      await loadData()
    } catch (error) {
      setFormError(error instanceof ApiError ? error.message : 'No se pudo actualizar el producto')
    } finally {
      setIsSubmitting(false)
    }
  }

  function openDeleteModal(producto: Producto) {
    setDeleteError(null)
    setProductoToDelete(producto)
  }

  function closeDeleteModal() {
    setProductoToDelete(null)
    setDeleteError(null)
  }

  async function confirmDelete() {
    if (!productoToDelete) {
      return
    }

    setIsDeleting(true)
    setDeleteError(null)

    try {
      const response = await productosService.remove(empresaId, productoToDelete.id)
      setSuccessMessage(response.message ?? 'Producto eliminado exitosamente')
      closeDeleteModal()
      await loadData()
    } catch (error) {
      setDeleteError(error instanceof ApiError ? error.message : 'No se pudo eliminar el producto')
    } finally {
      setIsDeleting(false)
    }
  }

  return (
    <AppLayout>
      <p className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
      </p>

      <div className="page-header">
        <div>
          <h1>Productos</h1>
          <p className="page-header__subtitle">
            {empresa
              ? `${empresa.razon_social} — catálogo para emisión de DTE.`
              : 'Catálogo de productos y servicios facturables.'}
          </p>
        </div>
        {canEdit ? <Button onClick={openCreateModal}>Nuevo producto</Button> : null}
      </div>

      {pageError ? <Alert variant="error">{pageError}</Alert> : null}
      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {listError ? <Alert variant="error">{listError}</Alert> : null}

      {!pageError ? (
        <>
          <div className="page-toolbar">
            <Input
              label="Buscar"
              name="q"
              placeholder="Código o nombre…"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              className="page-toolbar__search"
            />
            <div className="page-toolbar__filters">
              <span className="page-toolbar__filters-label">Estado:</span>
              {ACTIVO_OPCIONES.map((opcion) => (
                <button
                  key={opcion.value}
                  type="button"
                  className={`filter-chip ${activoFiltro === opcion.value ? 'filter-chip--active' : ''}`}
                  onClick={() => setActivoFiltro(opcion.value)}
                >
                  {opcion.label}
                </button>
              ))}
            </div>
          </div>

          {isLoading ? (
            <p className="page-loading">Cargando productos…</p>
          ) : productos.length === 0 ? (
            <p className="page-empty">No hay productos que coincidan con los filtros.</p>
          ) : (
            <div className="data-table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Código</th>
                    <th>Nombre</th>
                    <th>Precio neto</th>
                    <th>Precio con impuestos</th>
                    <th>Impuestos</th>
                    <th>Estado</th>
                    {canEdit ? <th aria-label="Acciones" /> : null}
                  </tr>
                </thead>
                <tbody>
                  {productos.map((producto) => (
                    <tr key={producto.id}>
                      <td>{producto.codigo}</td>
                      <td>{producto.nombre}</td>
                      <td>{formatPrecioProducto(producto.precio_unitario)}</td>
                      <td>{formatPrecioProducto(precioConImpuestosProducto(producto))}</td>
                      <td>
                        <span
                          className={`badge ${producto.afecto ? 'badge--info' : 'badge--neutral'}`}
                        >
                          {impuestosProductoLabel(producto)}
                        </span>
                      </td>
                      <td>
                        <span
                          className={`badge ${producto.activo ? 'badge--success' : 'badge--muted'}`}
                        >
                          {producto.activo ? 'Activo' : 'Inactivo'}
                        </span>
                        {producto.tiene_ventas ? (
                          <span className="producto-table__hint">Con ventas</span>
                        ) : null}
                      </td>
                      {canEdit ? (
                        <td className="data-table__actions">
                          <ProductoRowActions
                            producto={producto}
                            canEdit={canEdit}
                            onEdit={openEditModal}
                            onDelete={openDeleteModal}
                          />
                        </td>
                      ) : null}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      ) : null}

      {formMode === 'create' ? (
        <ProductoFormModal
          mode="create"
          impuestosDisponibles={impuestosDisponibles}
          isOpen
          isLoading={isSubmitting}
          error={formError}
          onClose={closeFormModal}
          onSubmit={handleCreate}
        />
      ) : null}

      {formMode === 'edit' && selectedProducto ? (
        <ProductoFormModal
          mode="edit"
          producto={selectedProducto}
          impuestosDisponibles={impuestosDisponibles}
          isOpen
          isLoading={isSubmitting}
          error={formError}
          onClose={closeFormModal}
          onSubmit={handleUpdate}
        />
      ) : null}

      <ConfirmDeleteModal
        isOpen={productoToDelete !== null}
        title="Eliminar producto"
        itemName={productoToDelete ? `${productoToDelete.codigo} — ${productoToDelete.nombre}` : ''}
        description={
          productoToDelete?.tiene_ventas
            ? 'Este producto tiene documentos emitidos y no puede eliminarse. Desactívelo en su lugar.'
            : undefined
        }
        isDeleting={isDeleting}
        error={deleteError}
        onConfirm={() => void confirmDelete()}
        onCancel={closeDeleteModal}
      />
    </AppLayout>
  )
}
