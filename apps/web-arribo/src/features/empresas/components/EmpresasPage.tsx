import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDeleteModal } from '@/components/ui'
import { EmpresaFormPanel } from '@/features/empresas/components/EmpresaForm'
import { EmpresaRowActions } from '@/features/empresas/components/EmpresaRowActions'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa, EmpresaInput } from '@/features/empresas/types/empresa.types'
import { ApiError } from '@/services/apiClient'

type ViewMode = 'list' | 'create' | 'edit'

function formatDate(value: string) {
  if (!value) {
    return '—'
  }

  return new Date(value).toLocaleDateString('es-CL')
}

export function EmpresasPage() {
  const navigate = useNavigate()
  const [empresas, setEmpresas] = useState<Empresa[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [viewMode, setViewMode] = useState<ViewMode>('list')
  const [selectedEmpresa, setSelectedEmpresa] = useState<Empresa | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [listError, setListError] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [empresaToDelete, setEmpresaToDelete] = useState<Empresa | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  const loadEmpresas = useCallback(async () => {
    setListError(null)
    setIsLoading(true)

    try {
      const response = await empresasService.list()
      setEmpresas(response.data)
    } catch (error) {
      setListError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar las empresas',
      )
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadEmpresas()
  }, [loadEmpresas])

  function openCreateForm() {
    setSelectedEmpresa(null)
    setFormError(null)
    setSuccessMessage(null)
    setViewMode('create')
  }

  function openEditForm(empresa: Empresa) {
    setSelectedEmpresa(empresa)
    setFormError(null)
    setSuccessMessage(null)
    setViewMode('edit')
  }

  function closeForm() {
    setSelectedEmpresa(null)
    setFormError(null)
    setViewMode('list')
  }

  async function handleCreate(values: EmpresaInput) {
    setIsSubmitting(true)
    setFormError(null)

    try {
      const response = await empresasService.create(values)
      setSuccessMessage(response.message ?? 'Empresa creada exitosamente')
      closeForm()
      await loadEmpresas()
    } catch (error) {
      setFormError(
        error instanceof ApiError ? error.message : 'No se pudo crear la empresa',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleUpdate(values: EmpresaInput) {
    if (!selectedEmpresa) {
      return
    }

    setIsSubmitting(true)
    setFormError(null)

    try {
      const response = await empresasService.update(selectedEmpresa.id, values)
      setSuccessMessage(response.message ?? 'Empresa actualizada exitosamente')
      closeForm()
      await loadEmpresas()
    } catch (error) {
      setFormError(
        error instanceof ApiError ? error.message : 'No se pudo actualizar la empresa',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  function openDeleteModal(empresa: Empresa) {
    setEmpresaToDelete(empresa)
    setDeleteError(null)
  }

  function closeDeleteModal() {
    setEmpresaToDelete(null)
    setDeleteError(null)
    setIsDeleting(false)
  }

  async function confirmDelete() {
    if (!empresaToDelete) {
      return
    }

    setIsDeleting(true)
    setDeleteError(null)
    setListError(null)
    setSuccessMessage(null)

    try {
      const response = await empresasService.remove(empresaToDelete.id)
      setSuccessMessage(response.message ?? 'Empresa eliminada exitosamente')
      closeDeleteModal()
      await loadEmpresas()
    } catch (error) {
      setDeleteError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo eliminar la empresa',
      )
    } finally {
      setIsDeleting(false)
    }
  }

  if (isLoading) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando empresas…</p>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Empresas</h1>
          <p className="page-header__subtitle">
            Administra las empresas emisoras de documentos tributarios.
          </p>
        </div>
        {viewMode === 'list' ? (
          <Button onClick={openCreateForm}>Nueva empresa</Button>
        ) : null}
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {listError ? <Alert variant="error">{listError}</Alert> : null}

      {viewMode === 'create' ? (
        <EmpresaFormPanel
          title="Nueva empresa"
          isSubmitting={isSubmitting}
          error={formError}
          onSubmit={handleCreate}
          onCancel={closeForm}
        />
      ) : null}

      {viewMode === 'edit' && selectedEmpresa ? (
        <EmpresaFormPanel
          title={`Editar: ${selectedEmpresa.razon_social}`}
          empresa={selectedEmpresa}
          isSubmitting={isSubmitting}
          error={formError}
          onSubmit={handleUpdate}
          onCancel={closeForm}
        />
      ) : null}

      {viewMode === 'list' ? (
        <section className="panel-card">
          {empresas.length === 0 ? (
            <p className="placeholder">No hay empresas registradas.</p>
          ) : (
            <div className="data-table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>RUT</th>
                    <th>Razón social</th>
                    <th>País</th>
                    <th>Nombre fantasía</th>
                    <th>Fecha resolución</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {empresas.map((empresa) => (
                    <tr key={empresa.id}>
                      <td>{empresa.rut}</td>
                      <td>{empresa.razon_social}</td>
                      <td>{empresa.pais?.nombre ?? '—'}</td>
                      <td>{empresa.nombre_fantasia}</td>
                      <td>{formatDate(empresa.fecha_resolucion)}</td>
                      <td>
                        <EmpresaRowActions
                          empresa={empresa}
                          onEdit={openEditForm}
                          onDelete={openDeleteModal}
                          onActecos={(item) =>
                            navigate(`/empresas/${item.id}/actecos`)
                          }
                          onPersonasAutorizadas={(item) =>
                            navigate(`/empresas/${item.id}/personas-autorizadas`)
                          }
                          onCertificados={(item) =>
                            navigate(`/empresas/${item.id}/certificados`)
                          }
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      ) : null}

      <ConfirmDeleteModal
        isOpen={empresaToDelete !== null}
        title="Eliminar empresa"
        itemName={empresaToDelete?.razon_social ?? ''}
        description="Si la empresa tiene usuarios, documentos u otros registros asociados, no se podrá eliminar. Esta acción no se puede deshacer."
        isDeleting={isDeleting}
        error={deleteError}
        onConfirm={confirmDelete}
        onCancel={closeDeleteModal}
      />
    </AppLayout>
  )
}
