import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDialog, Input } from '@/components/ui'
import { TipoHabilitadoEditModal } from '@/features/empresas/components/TipoHabilitadoEditModal'
import { empresaTiposHabilitadosService } from '@/features/empresas/services/empresaTiposHabilitadosService'
import { empresasService } from '@/features/empresas/services/empresasService'
import { tipoDocumentosService } from '@/features/empresas/services/tipoDocumentosService'
import type { TipoDocumento } from '@/features/empresas/types/tipoDocumento.types'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import type { TipoHabilitado } from '@/features/empresas/types/tipoHabilitado.types'
import type { TipoHabilitadoUpdateInput } from '@/features/empresas/types/tipoHabilitado.types'
import {
  defaultFechaHabilitacionInput,
  formatFechaHabilitacion,
  puedeQuitarHabilitacion,
} from '@/features/empresas/types/tipoHabilitado.types'
import { ApiError } from '@/services/apiClient'

export function EmpresaTiposDocumentosPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [assignedTipos, setAssignedTipos] = useState<TipoHabilitado[]>([])
  const [searchResults, setSearchResults] = useState<TipoDocumento[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [fechaHabilitacion, setFechaHabilitacion] = useState(defaultFechaHabilitacionInput())

  const [isLoading, setIsLoading] = useState(true)
  const [isSearching, setIsSearching] = useState(false)
  const [assigningTipoId, setAssigningTipoId] = useState<number | null>(null)

  const [tipoToEdit, setTipoToEdit] = useState<TipoHabilitado | null>(null)
  const [isUpdating, setIsUpdating] = useState(false)
  const [updateError, setUpdateError] = useState<string | null>(null)

  const [tipoToRemove, setTipoToRemove] = useState<TipoHabilitado | null>(null)
  const [isRemoving, setIsRemoving] = useState(false)
  const [removeError, setRemoveError] = useState<string | null>(null)

  const [pageError, setPageError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const loadAssigned = useCallback(async () => {
    const response = await empresaTiposHabilitadosService.listAssigned(empresaId)
    setAssignedTipos(response.data)
  }, [empresaId])

  const loadPage = useCallback(async () => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      setPageError('Empresa no válida')
      setIsLoading(false)
      return
    }

    setPageError(null)
    setIsLoading(true)

    try {
      const [empresaResponse, assignedResponse] = await Promise.all([
        empresasService.get(empresaId),
        empresaTiposHabilitadosService.listAssigned(empresaId),
      ])

      setEmpresa(empresaResponse.data)
      setAssignedTipos(assignedResponse.data)
    } catch (error) {
      setPageError(
        error instanceof ApiError
          ? error.message
          : 'No se pudieron cargar los tipos de documento',
      )
    } finally {
      setIsLoading(false)
    }
  }, [empresaId])

  useEffect(() => {
    void loadPage()
  }, [loadPage])

  useEffect(() => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      return
    }

    const timeoutId = window.setTimeout(async () => {
      setIsSearching(true)
      setActionError(null)

      try {
        const response = await tipoDocumentosService.searchCatalog(searchQuery, empresaId)
        setSearchResults(response.data)
      } catch (error) {
        setActionError(
          error instanceof ApiError
            ? error.message
            : 'No se pudo buscar en el catálogo de tipos de documento',
        )
      } finally {
        setIsSearching(false)
      }
    }, 300)

    return () => window.clearTimeout(timeoutId)
  }, [empresaId, searchQuery])

  async function handleAssign(tipo: TipoDocumento) {
    setAssigningTipoId(tipo.id)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaTiposHabilitadosService.assign(empresaId, {
        tipo_documento_id: tipo.id,
        fecha_habilitacion: fechaHabilitacion,
      })
      setSuccessMessage(
        response.message ?? 'Tipo de documento habilitado exitosamente',
      )
      await loadAssigned()
      setSearchResults((current) => current.filter((item) => item.id !== tipo.id))
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo habilitar el tipo de documento',
      )
    } finally {
      setAssigningTipoId(null)
    }
  }

  function openEditModal(tipo: TipoHabilitado) {
    setTipoToEdit(tipo)
    setUpdateError(null)
  }

  function closeEditModal() {
    setTipoToEdit(null)
    setUpdateError(null)
    setIsUpdating(false)
  }

  async function handleUpdate(values: TipoHabilitadoUpdateInput) {
    if (!tipoToEdit) {
      return
    }

    setIsUpdating(true)
    setUpdateError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaTiposHabilitadosService.update(
        empresaId,
        tipoToEdit.id,
        values,
      )
      setSuccessMessage(response.message ?? 'Habilitación actualizada exitosamente')
      closeEditModal()
      await loadAssigned()
    } catch (error) {
      setUpdateError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo actualizar la habilitación',
      )
    } finally {
      setIsUpdating(false)
    }
  }

  function openRemoveModal(tipo: TipoHabilitado) {
    setTipoToRemove(tipo)
    setRemoveError(null)
  }

  function closeRemoveModal() {
    setTipoToRemove(null)
    setRemoveError(null)
    setIsRemoving(false)
  }

  async function confirmRemove() {
    if (!tipoToRemove) {
      return
    }

    setIsRemoving(true)
    setRemoveError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaTiposHabilitadosService.remove(
        empresaId,
        tipoToRemove.id,
      )
      setSuccessMessage(
        response.message ?? 'Tipo de documento quitado exitosamente',
      )
      closeRemoveModal()
      await loadAssigned()
    } catch (error) {
      setRemoveError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo quitar la habilitación',
      )
    } finally {
      setIsRemoving(false)
    }
  }

  if (isLoading) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando tipos de documento…</p>
      </AppLayout>
    )
  }

  if (pageError) {
    return (
      <AppLayout>
        <Alert variant="error">{pageError}</Alert>
        <p className="page-back-link">
          <Link to="/empresas">← Volver a empresas</Link>
        </p>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <p className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
      </p>

      <div className="page-header">
        <div>
          <h1>Tipos de documento</h1>
          <p className="page-header__subtitle">
            {empresa?.razon_social ?? 'Empresa'} — habilitación para emisión DTE y
            carga de CAF
          </p>
        </div>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      <section className="panel-card">
        <h2>Habilitados</h2>
        {assignedTipos.length === 0 ? (
          <p className="placeholder">
            Esta empresa no tiene tipos de documento habilitados. Habilite al menos
            uno antes de cargar archivos CAF.
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Código</th>
                  <th>Nombre</th>
                  <th>Fecha habilitación</th>
                  <th>Folios disponibles</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {assignedTipos.map((tipo) => (
                  <tr key={tipo.id}>
                    <td>{tipo.tipo_documento.codigo}</td>
                    <td>{tipo.tipo_documento.nombre}</td>
                    <td>{formatFechaHabilitacion(tipo.fecha_habilitacion)}</td>
                    <td>{tipo.folios_disponibles}</td>
                    <td>
                      <div className="table-actions">
                        <Button
                          variant="secondary"
                          onClick={() => openEditModal(tipo)}
                        >
                          Editar
                        </Button>
                        <Button
                          variant="secondary"
                          disabled={!puedeQuitarHabilitacion(tipo)}
                          onClick={() => openRemoveModal(tipo)}
                        >
                          Quitar
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="panel-card actecos-search-panel">
        <h2>Habilitar tipo de documento</h2>
        <div className="empresa-form__grid">
          <Input
            label="Buscar por código o nombre"
            name="tipo-documento-search"
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
            placeholder="Ej: 33 o Factura"
          />
          <Input
            label="Fecha habilitación (para nuevas asignaciones)"
            name="fecha-habilitacion"
            type="datetime-local"
            value={fechaHabilitacion}
            onChange={(event) => setFechaHabilitacion(event.target.value)}
          />
        </div>

        {isSearching ? (
          <p className="placeholder">Buscando…</p>
        ) : searchResults.length === 0 ? (
          <p className="placeholder">
            {searchQuery.trim()
              ? 'No hay resultados para esa búsqueda.'
              : 'Todos los tipos DTE ya están habilitados o escriba un término para buscar.'}
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Código</th>
                  <th>Nombre</th>
                  <th>Acción</th>
                </tr>
              </thead>
              <tbody>
                {searchResults.map((tipo) => (
                  <tr key={tipo.id}>
                    <td>{tipo.codigo}</td>
                    <td>{tipo.nombre}</td>
                    <td>
                      <Button
                        disabled={assigningTipoId === tipo.id}
                        onClick={() => void handleAssign(tipo)}
                      >
                        {assigningTipoId === tipo.id ? 'Habilitando…' : 'Habilitar'}
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <TipoHabilitadoEditModal
        tipo={tipoToEdit}
        isOpen={tipoToEdit !== null}
        isLoading={isUpdating}
        error={updateError}
        onClose={closeEditModal}
        onSubmit={handleUpdate}
      />

      <ConfirmDialog
        isOpen={tipoToRemove !== null}
        title="Quitar habilitación"
        confirmLabel="Quitar"
        variant="danger"
        isLoading={isRemoving}
        error={removeError}
        onConfirm={confirmRemove}
        onCancel={closeRemoveModal}
      >
        <p>
          ¿Está seguro de quitar{' '}
          <strong>
            {tipoToRemove?.tipo_documento.codigo} — {tipoToRemove?.tipo_documento.nombre}
          </strong>{' '}
          de esta empresa?
        </p>
        {tipoToRemove && !puedeQuitarHabilitacion(tipoToRemove) ? (
          <p>
            No se puede quitar porque tiene rangos CAF cargados o documentos emitidos.
          </p>
        ) : (
          <p>Podrá volver a habilitarlo desde el catálogo.</p>
        )}
      </ConfirmDialog>
    </AppLayout>
  )
}
