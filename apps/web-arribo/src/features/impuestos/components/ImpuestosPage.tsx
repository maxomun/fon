import { useCallback, useEffect, useState } from 'react'
import { AppLayout } from '@/components/layout/AppLayout'
import {
  Alert,
  Button,
  ConfirmDeleteModal,
  ConfirmDialog,
  DropdownMenu,
} from '@/components/ui'
import { ImpuestoFormModal } from '@/features/impuestos/components/ImpuestoFormModal'
import { ImpuestoValorFormModal } from '@/features/impuestos/components/ImpuestoValorFormModal'
import { impuestoValoresService } from '@/features/impuestos/services/impuestoValoresService'
import { impuestosService } from '@/features/impuestos/services/impuestosService'
import type {
  Impuesto,
  ImpuestoInput,
  ImpuestoUpdateInput,
} from '@/features/impuestos/types/impuesto.types'
import { formatValorVigente } from '@/features/impuestos/types/impuesto.types'
import type { ImpuestoValor, ImpuestoValorInput } from '@/features/impuestos/types/impuestoValor.types'
import {
  formatDateTime,
  formatSiNo,
} from '@/features/impuestos/types/impuestoValor.types'
import { paisesService } from '@/features/empresas/services/paisesService'
import { findPaisChile, type Pais } from '@/features/empresas/types/pais.types'
import { useTableRowSelection } from '@/hooks/useTableRowSelection'
import {
  buildInteractiveRowProps,
  stopRowClickPropagation,
} from '@/lib/interactiveTableRow'
import { ApiError } from '@/services/apiClient'

export function ImpuestosPage() {
  const [paises, setPaises] = useState<Pais[]>([])
  const [selectedPaisId, setSelectedPaisId] = useState<number | null>(null)
  const [impuestos, setImpuestos] = useState<Impuesto[]>([])
  const [selectedImpuesto, setSelectedImpuesto] = useState<Impuesto | null>(null)
  const [valores, setValores] = useState<ImpuestoValor[]>([])
  const valorRowSelection = useTableRowSelection()

  const [isLoadingPaises, setIsLoadingPaises] = useState(true)
  const [isLoadingImpuestos, setIsLoadingImpuestos] = useState(false)
  const [isLoadingValores, setIsLoadingValores] = useState(false)

  const [pageError, setPageError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const [impuestoModalMode, setImpuestoModalMode] = useState<'create' | 'edit' | null>(
    null,
  )
  const [impuestoToEdit, setImpuestoToEdit] = useState<Impuesto | null>(null)
  const [isSavingImpuesto, setIsSavingImpuesto] = useState(false)
  const [impuestoFormError, setImpuestoFormError] = useState<string | null>(null)

  const [valorModalMode, setValorModalMode] = useState<'create' | 'edit' | null>(null)
  const [valorToEdit, setValorToEdit] = useState<ImpuestoValor | null>(null)
  const [isSavingValor, setIsSavingValor] = useState(false)
  const [valorFormError, setValorFormError] = useState<string | null>(null)

  const [impuestoToDelete, setImpuestoToDelete] = useState<Impuesto | null>(null)
  const [isDeletingImpuesto, setIsDeletingImpuesto] = useState(false)
  const [deleteImpuestoError, setDeleteImpuestoError] = useState<string | null>(null)

  const [valorToDelete, setValorToDelete] = useState<ImpuestoValor | null>(null)
  const [isDeletingValor, setIsDeletingValor] = useState(false)
  const [deleteValorError, setDeleteValorError] = useState<string | null>(null)

  const loadImpuestos = useCallback(async (paisId: number) => {
    setIsLoadingImpuestos(true)
    setPageError(null)

    try {
      const response = await impuestosService.list(paisId)
      setImpuestos(response.data)
      setSelectedImpuesto((current) => {
        if (!current) {
          return null
        }

        return response.data.find((item) => item.id === current.id) ?? null
      })
    } catch (error) {
      setPageError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar los impuestos',
      )
      setImpuestos([])
    } finally {
      setIsLoadingImpuestos(false)
    }
  }, [])

  const loadValores = useCallback(async (impuestoId: number) => {
    setIsLoadingValores(true)
    setActionError(null)

    try {
      const response = await impuestoValoresService.list(impuestoId)
      setValores(response.data)
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudieron cargar los valores del impuesto',
      )
      setValores([])
    } finally {
      setIsLoadingValores(false)
    }
  }, [])

  useEffect(() => {
    async function loadPaises() {
      setIsLoadingPaises(true)
      setPageError(null)

      try {
        const response = await paisesService.list()
        setPaises(response.data)

        const paisChile = findPaisChile(response.data)
        setSelectedPaisId(paisChile?.id ?? response.data[0]?.id ?? null)
      } catch (error) {
        setPageError(
          error instanceof ApiError ? error.message : 'No se pudieron cargar los países',
        )
      } finally {
        setIsLoadingPaises(false)
      }
    }

    void loadPaises()
  }, [])

  useEffect(() => {
    if (selectedPaisId === null) {
      return
    }

    setSelectedImpuesto(null)
    setValores([])
    void loadImpuestos(selectedPaisId)
  }, [selectedPaisId, loadImpuestos])

  useEffect(() => {
    if (!selectedImpuesto) {
      setValores([])
      return
    }

    void loadValores(selectedImpuesto.id)
  }, [selectedImpuesto, loadValores])

  function openCreateImpuestoModal() {
    setImpuestoToEdit(null)
    setImpuestoFormError(null)
    setImpuestoModalMode('create')
  }

  function openEditImpuestoModal(impuesto: Impuesto) {
    setImpuestoToEdit(impuesto)
    setImpuestoFormError(null)
    setImpuestoModalMode('edit')
  }

  function closeImpuestoModal() {
    setImpuestoModalMode(null)
    setImpuestoToEdit(null)
    setImpuestoFormError(null)
    setIsSavingImpuesto(false)
  }

  async function handleCreateImpuesto(values: ImpuestoInput) {
    if (selectedPaisId === null) {
      return
    }

    setIsSavingImpuesto(true)
    setImpuestoFormError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await impuestosService.create({
        ...values,
        pais_id: selectedPaisId,
      })
      setSuccessMessage(response.message ?? 'Impuesto creado exitosamente')
      closeImpuestoModal()
      await loadImpuestos(selectedPaisId)
      setSelectedImpuesto(response.data)
    } catch (error) {
      setImpuestoFormError(
        error instanceof ApiError ? error.message : 'No se pudo crear el impuesto',
      )
    } finally {
      setIsSavingImpuesto(false)
    }
  }

  async function handleUpdateImpuesto(values: ImpuestoUpdateInput) {
    if (!impuestoToEdit || selectedPaisId === null) {
      return
    }

    setIsSavingImpuesto(true)
    setImpuestoFormError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await impuestosService.update(impuestoToEdit.id, values)
      setSuccessMessage(response.message ?? 'Impuesto actualizado exitosamente')
      closeImpuestoModal()
      await loadImpuestos(selectedPaisId)
      setSelectedImpuesto(response.data)
    } catch (error) {
      setImpuestoFormError(
        error instanceof ApiError ? error.message : 'No se pudo actualizar el impuesto',
      )
    } finally {
      setIsSavingImpuesto(false)
    }
  }

  function openDeleteImpuestoModal(impuesto: Impuesto) {
    setImpuestoToDelete(impuesto)
    setDeleteImpuestoError(null)
  }

  function closeDeleteImpuestoModal() {
    setImpuestoToDelete(null)
    setDeleteImpuestoError(null)
    setIsDeletingImpuesto(false)
  }

  async function confirmDeleteImpuesto() {
    if (!impuestoToDelete || selectedPaisId === null) {
      return
    }

    setIsDeletingImpuesto(true)
    setDeleteImpuestoError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await impuestosService.remove(impuestoToDelete.id)
      setSuccessMessage(response.message ?? 'Impuesto eliminado exitosamente')
      closeDeleteImpuestoModal()

      if (selectedImpuesto?.id === impuestoToDelete.id) {
        setSelectedImpuesto(null)
      }

      await loadImpuestos(selectedPaisId)
    } catch (error) {
      setDeleteImpuestoError(
        error instanceof ApiError ? error.message : 'No se pudo eliminar el impuesto',
      )
    } finally {
      setIsDeletingImpuesto(false)
    }
  }

  function openCreateValorModal() {
    setValorToEdit(null)
    setValorFormError(null)
    setValorModalMode('create')
  }

  function openEditValorModal(valor: ImpuestoValor) {
    setValorToEdit(valor)
    setValorFormError(null)
    setValorModalMode('edit')
  }

  function closeValorModal() {
    setValorModalMode(null)
    setValorToEdit(null)
    setValorFormError(null)
    setIsSavingValor(false)
  }

  async function handleCreateValor(values: ImpuestoValorInput) {
    if (!selectedImpuesto || selectedPaisId === null) {
      return
    }

    setIsSavingValor(true)
    setValorFormError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await impuestoValoresService.create(selectedImpuesto.id, values)
      setSuccessMessage(response.message ?? 'Valor registrado exitosamente')
      closeValorModal()
      await Promise.all([
        loadValores(selectedImpuesto.id),
        loadImpuestos(selectedPaisId),
      ])
    } catch (error) {
      setValorFormError(
        error instanceof ApiError ? error.message : 'No se pudo registrar el valor',
      )
    } finally {
      setIsSavingValor(false)
    }
  }

  async function handleUpdateValor(values: ImpuestoValorInput) {
    if (!selectedImpuesto || !valorToEdit || selectedPaisId === null) {
      return
    }

    setIsSavingValor(true)
    setValorFormError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await impuestoValoresService.update(
        selectedImpuesto.id,
        valorToEdit.id,
        values,
      )
      setSuccessMessage(response.message ?? 'Valor actualizado exitosamente')
      closeValorModal()
      await Promise.all([
        loadValores(selectedImpuesto.id),
        loadImpuestos(selectedPaisId),
      ])
    } catch (error) {
      setValorFormError(
        error instanceof ApiError ? error.message : 'No se pudo actualizar el valor',
      )
    } finally {
      setIsSavingValor(false)
    }
  }

  function openDeleteValorModal(valor: ImpuestoValor) {
    setValorToDelete(valor)
    setDeleteValorError(null)
  }

  function closeDeleteValorModal() {
    setValorToDelete(null)
    setDeleteValorError(null)
    setIsDeletingValor(false)
  }

  async function confirmDeleteValor() {
    if (!selectedImpuesto || !valorToDelete || selectedPaisId === null) {
      return
    }

    setIsDeletingValor(true)
    setDeleteValorError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await impuestoValoresService.remove(
        selectedImpuesto.id,
        valorToDelete.id,
      )
      setSuccessMessage(response.message ?? 'Valor eliminado exitosamente')
      closeDeleteValorModal()
      await Promise.all([
        loadValores(selectedImpuesto.id),
        loadImpuestos(selectedPaisId),
      ])
    } catch (error) {
      setDeleteValorError(
        error instanceof ApiError ? error.message : 'No se pudo eliminar el valor',
      )
    } finally {
      setIsDeletingValor(false)
    }
  }

  const selectedPais = paises.find((pais) => pais.id === selectedPaisId) ?? null

  if (isLoadingPaises) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando impuestos…</p>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Impuestos</h1>
          <p className="page-header__subtitle">
            Catálogo de impuestos y valores históricos por país.
          </p>
        </div>
        <Button
          onClick={openCreateImpuestoModal}
          disabled={selectedPaisId === null}
        >
          Nuevo impuesto
        </Button>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {pageError ? <Alert variant="error">{pageError}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      <section className="panel-card actecos-search-panel">
        <div className="field">
          <label htmlFor="impuestos-pais">País</label>
          <select
            id="impuestos-pais"
            className="select-input"
            value={selectedPaisId ?? ''}
            onChange={(event) => setSelectedPaisId(Number(event.target.value))}
          >
            {paises.map((pais) => (
              <option key={pais.id} value={pais.id}>
                {pais.nombre} ({pais.codigo})
              </option>
            ))}
          </select>
        </div>
      </section>

      <section className="panel-card">
        <h2>
          Impuestos{selectedPais ? ` — ${selectedPais.nombre}` : ''}
        </h2>

        {isLoadingImpuestos ? (
          <p className="placeholder">Cargando impuestos…</p>
        ) : impuestos.length === 0 ? (
          <p className="placeholder">
            Este país no tiene impuestos registrados.
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table data-table--interactive">
              <thead>
                <tr>
                  <th>Abreviación</th>
                  <th>Nombre</th>
                  <th>Valor vigente</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {impuestos.map((impuesto) => {
                  const isImpuestoSelected = selectedImpuesto?.id === impuesto.id

                  return (
                    <tr
                      key={impuesto.id}
                      {...buildInteractiveRowProps({
                        rowId: impuesto.id,
                        isSelected: isImpuestoSelected,
                        onSelect: (_id) => setSelectedImpuesto(impuesto),
                        onDoubleClick: () => openEditImpuestoModal(impuesto),
                      })}
                    >
                      <td>{impuesto.abreviacion}</td>
                      <td>{impuesto.nombre}</td>
                      <td>{formatValorVigente(impuesto.valor_vigente)}</td>
                      <td
                        className="data-table__actions"
                        onClick={stopRowClickPropagation}
                      >
                        <div className="table-actions">
                          <Button
                            variant="secondary"
                            onClick={() => setSelectedImpuesto(impuesto)}
                          >
                            Valores
                          </Button>
                          <DropdownMenu
                            ariaLabel={`Opciones de ${impuesto.abreviacion}`}
                            items={[
                              {
                                id: 'editar',
                                label: 'Editar',
                                onClick: () => openEditImpuestoModal(impuesto),
                              },
                              {
                                id: 'eliminar',
                                label: 'Eliminar',
                                variant: 'danger',
                                disabled: impuesto.tiene_productos,
                                onClick: () => openDeleteImpuestoModal(impuesto),
                              },
                            ]}
                          />
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {selectedImpuesto ? (
        <section className="panel-card">
          <div className="page-header">
            <div>
              <h2>Valores de {selectedImpuesto.abreviacion}</h2>
              <p className="page-header__subtitle">{selectedImpuesto.nombre}</p>
            </div>
            <Button onClick={openCreateValorModal}>Nuevo valor</Button>
          </div>

          {isLoadingValores ? (
            <p className="placeholder">Cargando valores…</p>
          ) : valores.length === 0 ? (
            <p className="placeholder">
              Este impuesto no tiene valores registrados.
            </p>
          ) : (
            <div className="data-table-wrapper">
              <table className="data-table data-table--interactive">
                <thead>
                  <tr>
                    <th>Valor (%)</th>
                    <th>Desde</th>
                    <th>Hasta</th>
                    <th>Vigente</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {valores.map((valor) => (
                    <tr
                      key={valor.id}
                      {...buildInteractiveRowProps({
                        rowId: valor.id,
                        isSelected: valorRowSelection.isSelected(valor.id),
                        onSelect: valorRowSelection.select,
                        onDoubleClick: () => openEditValorModal(valor),
                      })}
                    >
                      <td>{valor.valor}</td>
                      <td>{formatDateTime(valor.fecha_activacion)}</td>
                      <td>{formatDateTime(valor.fecha_caducacion)}</td>
                      <td>{formatSiNo(valor.vigente)}</td>
                      <td
                        className="data-table__actions"
                        onClick={stopRowClickPropagation}
                      >
                        <div className="table-actions">
                          <Button
                            variant="secondary"
                            onClick={() => openEditValorModal(valor)}
                          >
                            Editar
                          </Button>
                          <Button
                            variant="secondary"
                            onClick={() => openDeleteValorModal(valor)}
                          >
                            Eliminar
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
      ) : null}

      {impuestoModalMode === 'create' && selectedPaisId !== null ? (
        <ImpuestoFormModal
          mode="create"
          paisId={selectedPaisId}
          isOpen
          isLoading={isSavingImpuesto}
          error={impuestoFormError}
          onClose={closeImpuestoModal}
          onSubmit={handleCreateImpuesto}
        />
      ) : null}

      {impuestoModalMode === 'edit' ? (
        <ImpuestoFormModal
          mode="edit"
          impuesto={impuestoToEdit}
          isOpen
          isLoading={isSavingImpuesto}
          error={impuestoFormError}
          onClose={closeImpuestoModal}
          onSubmit={handleUpdateImpuesto}
        />
      ) : null}

      {valorModalMode === 'create' && selectedImpuesto ? (
        <ImpuestoValorFormModal
          mode="create"
          impuestoLabel={selectedImpuesto.abreviacion}
          isOpen
          isLoading={isSavingValor}
          error={valorFormError}
          onClose={closeValorModal}
          onSubmit={handleCreateValor}
        />
      ) : null}

      {valorModalMode === 'edit' ? (
        <ImpuestoValorFormModal
          mode="edit"
          valor={valorToEdit}
          impuestoLabel={selectedImpuesto?.abreviacion ?? ''}
          isOpen
          isLoading={isSavingValor}
          error={valorFormError}
          onClose={closeValorModal}
          onSubmit={handleUpdateValor}
        />
      ) : null}

      <ConfirmDeleteModal
        isOpen={impuestoToDelete !== null}
        title="Eliminar impuesto"
        itemName={impuestoToDelete?.abreviacion ?? ''}
        description={
          impuestoToDelete?.tiene_productos
            ? 'Este impuesto está asignado a productos y no puede eliminarse.'
            : 'Se eliminarán también todos sus valores históricos.'
        }
        isDeleting={isDeletingImpuesto}
        error={deleteImpuestoError}
        onConfirm={confirmDeleteImpuesto}
        onCancel={closeDeleteImpuestoModal}
      />

      <ConfirmDialog
        isOpen={valorToDelete !== null}
        title="Eliminar valor"
        confirmLabel="Eliminar"
        variant="danger"
        isLoading={isDeletingValor}
        error={deleteValorError}
        onConfirm={confirmDeleteValor}
        onCancel={closeDeleteValorModal}
      >
        <p>
          ¿Está seguro de eliminar el valor <strong>{valorToDelete?.valor}%</strong>?
        </p>
      </ConfirmDialog>
    </AppLayout>
  )
}
