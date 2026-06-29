import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDialog, Input } from '@/components/ui'
import { empresaActecosService } from '@/features/empresas/services/empresaActecosService'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Acteco } from '@/features/empresas/types/acteco.types'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import { useTableRowSelection } from '@/hooks/useTableRowSelection'
import {
  buildInteractiveRowProps,
  stopRowClickPropagation,
} from '@/lib/interactiveTableRow'
import { ApiError } from '@/services/apiClient'

function formatAfectoIva(value: boolean) {
  return value ? 'Sí' : 'No'
}

export function EmpresaActecosPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [assignedActecos, setAssignedActecos] = useState<Acteco[]>([])
  const [searchResults, setSearchResults] = useState<Acteco[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [isSearching, setIsSearching] = useState(false)
  const [assigningActecoId, setAssigningActecoId] = useState<number | null>(null)
  const [actecoToRemove, setActecoToRemove] = useState<Acteco | null>(null)
  const rowSelection = useTableRowSelection()
  const [isRemoving, setIsRemoving] = useState(false)
  const [removeError, setRemoveError] = useState<string | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const loadAssigned = useCallback(async () => {
    const response = await empresaActecosService.listAssigned(empresaId)
    setAssignedActecos(response.data)
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
        empresaActecosService.listAssigned(empresaId),
      ])

      setEmpresa(empresaResponse.data)
      setAssignedActecos(assignedResponse.data)
    } catch (error) {
      setPageError(
        error instanceof ApiError
          ? error.message
          : 'No se pudieron cargar las actividades económicas',
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
        const response = await empresaActecosService.searchCatalog(
          searchQuery,
          empresaId,
        )
        setSearchResults(response.data)
      } catch (error) {
        setActionError(
          error instanceof ApiError
            ? error.message
            : 'No se pudo buscar en el catálogo de actividades',
        )
      } finally {
        setIsSearching(false)
      }
    }, 300)

    return () => window.clearTimeout(timeoutId)
  }, [empresaId, searchQuery])

  async function handleAssign(acteco: Acteco) {
    setAssigningActecoId(acteco.id)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaActecosService.assign(empresaId, acteco.id)
      setSuccessMessage(
        response.message ?? 'Actividad económica asignada exitosamente',
      )
      await loadAssigned()
      setSearchResults((current) => current.filter((item) => item.id !== acteco.id))
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo asignar la actividad económica',
      )
    } finally {
      setAssigningActecoId(null)
    }
  }

  function openRemoveModal(acteco: Acteco) {
    setActecoToRemove(acteco)
    setRemoveError(null)
  }

  function closeRemoveModal() {
    setActecoToRemove(null)
    setRemoveError(null)
    setIsRemoving(false)
  }

  async function confirmRemove() {
    if (!actecoToRemove) {
      return
    }

    setIsRemoving(true)
    setRemoveError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaActecosService.remove(
        empresaId,
        actecoToRemove.id,
      )
      setSuccessMessage(
        response.message ?? 'Actividad económica quitada exitosamente',
      )
      closeRemoveModal()
      await loadAssigned()
    } catch (error) {
      setRemoveError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo quitar la actividad económica',
      )
    } finally {
      setIsRemoving(false)
    }
  }

  if (isLoading) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando actividades económicas…</p>
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
          <h1>Actividades económicas</h1>
          <p className="page-header__subtitle">
            {empresa?.razon_social ?? 'Empresa'} — asignación de códigos acteco
          </p>
        </div>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      <section className="panel-card">
        <h2>Asignadas</h2>
        {assignedActecos.length === 0 ? (
          <p className="placeholder">
            Esta empresa no tiene actividades económicas asignadas.
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table data-table--interactive">
              <thead>
                <tr>
                  <th>Código</th>
                  <th>Nombre</th>
                  <th>Grupo</th>
                  <th>Afecto IVA</th>
                  <th>Acción</th>
                </tr>
              </thead>
              <tbody>
                {assignedActecos.map((acteco) => (
                  <tr
                    key={acteco.id}
                    {...buildInteractiveRowProps({
                      rowId: acteco.id,
                      isSelected: rowSelection.isSelected(acteco.id),
                      onSelect: rowSelection.select,
                    })}
                  >
                    <td>{acteco.codigo}</td>
                    <td>{acteco.nombre}</td>
                    <td>{acteco.grupo_acteco.nombre}</td>
                    <td>{formatAfectoIva(acteco.afecto_iva)}</td>
                    <td
                      className="data-table__actions"
                      onClick={stopRowClickPropagation}
                    >
                      <Button
                        variant="secondary"
                        disabled={isRemoving && actecoToRemove?.id === acteco.id}
                        onClick={() => openRemoveModal(acteco)}
                      >
                        Quitar
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="panel-card actecos-search-panel">
        <h2>Agregar actividad</h2>
        <Input
          label="Buscar por código o nombre"
          name="acteco-search"
          value={searchQuery}
          onChange={(event) => setSearchQuery(event.target.value)}
          placeholder="Ej: 620100 o software"
        />

        {isSearching ? (
          <p className="placeholder">Buscando…</p>
        ) : searchResults.length === 0 ? (
          <p className="placeholder">
            {searchQuery.trim()
              ? 'No hay resultados para esa búsqueda.'
              : 'Escriba un código o nombre para buscar en el catálogo.'}
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table data-table--interactive">
              <thead>
                <tr>
                  <th>Código</th>
                  <th>Nombre</th>
                  <th>Grupo</th>
                  <th>Afecto IVA</th>
                  <th>Acción</th>
                </tr>
              </thead>
              <tbody>
                {searchResults.map((acteco) => (
                  <tr
                    key={acteco.id}
                    {...buildInteractiveRowProps({
                      rowId: acteco.id,
                      isSelected: rowSelection.isSelected(acteco.id),
                      onSelect: rowSelection.select,
                    })}
                  >
                    <td>{acteco.codigo}</td>
                    <td>{acteco.nombre}</td>
                    <td>{acteco.grupo_acteco.nombre}</td>
                    <td>{formatAfectoIva(acteco.afecto_iva)}</td>
                    <td
                      className="data-table__actions"
                      onClick={stopRowClickPropagation}
                    >
                      <Button
                        disabled={assigningActecoId === acteco.id}
                        onClick={() => void handleAssign(acteco)}
                      >
                        {assigningActecoId === acteco.id ? 'Agregando…' : 'Agregar'}
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <ConfirmDialog
        isOpen={actecoToRemove !== null}
        title="Quitar actividad económica"
        confirmLabel="Quitar"
        variant="danger"
        isLoading={isRemoving}
        error={removeError}
        onConfirm={confirmRemove}
        onCancel={closeRemoveModal}
      >
        <p>
          ¿Está seguro de quitar <strong>{actecoToRemove?.nombre}</strong> de esta
          empresa?
        </p>
        <p>La actividad seguirá disponible en el catálogo para volver a asignarla.</p>
      </ConfirmDialog>
    </AppLayout>
  )
}
