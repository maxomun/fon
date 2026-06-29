import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDialog } from '@/components/ui'
import { empresaRangosFoliosService } from '@/features/empresas/services/empresaRangosFoliosService'
import { empresaTiposHabilitadosService } from '@/features/empresas/services/empresaTiposHabilitadosService'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import type { RangoFolio } from '@/features/empresas/types/rangoFolio.types'
import {
  formatFechaRango,
  formatRangoFolios,
  puedeEliminarRango,
} from '@/features/empresas/types/rangoFolio.types'
import { useTableRowSelection } from '@/hooks/useTableRowSelection'
import {
  buildInteractiveRowProps,
  stopRowClickPropagation,
} from '@/lib/interactiveTableRow'
import { ApiError } from '@/services/apiClient'

export function EmpresaRangosFoliosPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [rangos, setRangos] = useState<RangoFolio[]>([])
  const [tiposHabilitadosCount, setTiposHabilitadosCount] = useState(0)
  const [archivoCaf, setArchivoCaf] = useState<File | null>(null)

  const [isLoading, setIsLoading] = useState(true)
  const [isUploading, setIsUploading] = useState(false)
  const [rangoToRemove, setRangoToRemove] = useState<RangoFolio | null>(null)
  const rowSelection = useTableRowSelection()
  const [isRemoving, setIsRemoving] = useState(false)
  const [removeError, setRemoveError] = useState<string | null>(null)

  const [pageError, setPageError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const loadRangos = useCallback(async () => {
    const response = await empresaRangosFoliosService.list(empresaId)
    setRangos(response.data)
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
      const [empresaResponse, rangosResponse, tiposResponse] = await Promise.all([
        empresasService.get(empresaId),
        empresaRangosFoliosService.list(empresaId),
        empresaTiposHabilitadosService.listAssigned(empresaId),
      ])

      setEmpresa(empresaResponse.data)
      setRangos(rangosResponse.data)
      setTiposHabilitadosCount(tiposResponse.data.length)
    } catch (error) {
      setPageError(
        error instanceof ApiError
          ? error.message
          : 'No se pudieron cargar los rangos de folios',
      )
    } finally {
      setIsLoading(false)
    }
  }, [empresaId])

  useEffect(() => {
    void loadPage()
  }, [loadPage])

  async function handleUpload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setActionError(null)
    setSuccessMessage(null)

    if (!archivoCaf) {
      setActionError('Debe seleccionar un archivo CAF (.xml)')
      return
    }

    if (!archivoCaf.name.toLowerCase().endsWith('.xml')) {
      setActionError('El archivo CAF debe ser un XML')
      return
    }

    setIsUploading(true)

    try {
      const response = await empresaRangosFoliosService.upload(empresaId, archivoCaf)
      setSuccessMessage(response.message ?? 'Archivo CAF cargado correctamente')
      setArchivoCaf(null)
      await loadRangos()
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo cargar el archivo CAF',
      )
    } finally {
      setIsUploading(false)
    }
  }

  function openRemoveModal(rango: RangoFolio) {
    setRangoToRemove(rango)
    setRemoveError(null)
  }

  function closeRemoveModal() {
    setRangoToRemove(null)
    setRemoveError(null)
    setIsRemoving(false)
  }

  async function confirmRemove() {
    if (!rangoToRemove) {
      return
    }

    setIsRemoving(true)
    setRemoveError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaRangosFoliosService.remove(
        empresaId,
        rangoToRemove.id,
      )
      setSuccessMessage(response.message ?? 'Rango de folio eliminado correctamente')
      closeRemoveModal()
      await loadRangos()
    } catch (error) {
      setRemoveError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo eliminar el rango de folios',
      )
    } finally {
      setIsRemoving(false)
    }
  }

  if (isLoading) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando rangos de folios…</p>
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
        {' · '}
        <Link to={`/empresas/${empresaId}/tipos-documentos`}>Tipos de documento</Link>
      </p>

      <div className="page-header">
        <div>
          <h1>Rangos de folios (CAF)</h1>
          <p className="page-header__subtitle">
            {empresa?.razon_social ?? 'Empresa'} — autorización de folios del SII
          </p>
        </div>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      {tiposHabilitadosCount === 0 ? (
        <div className="alert alert-error">
          Esta empresa no tiene tipos de documento habilitados.{' '}
          <Link to={`/empresas/${empresaId}/tipos-documentos`}>
            Habilite al menos un tipo
          </Link>{' '}
          antes de cargar archivos CAF.
        </div>
      ) : null}

      <section className="panel-card actecos-search-panel">
        <h2>Cargar archivo CAF</h2>
        <p className="page-header__subtitle">
          El tipo de documento se detecta automáticamente desde el XML (campo TD).
        </p>
        <form className="empresa-form" onSubmit={handleUpload}>
          <div className="empresa-form__grid">
            <div className="field">
              <label htmlFor="archivo-caf">Archivo CAF (.xml)</label>
              <input
                id="archivo-caf"
                type="file"
                accept=".xml"
                disabled={isUploading || tiposHabilitadosCount === 0}
                onChange={(event) => setArchivoCaf(event.target.files?.[0] ?? null)}
                required
              />
            </div>
          </div>
          <div className="empresa-form__actions">
            <Button
              type="submit"
              disabled={isUploading || tiposHabilitadosCount === 0}
              isLoading={isUploading}
            >
              {isUploading ? 'Subiendo…' : 'Subir CAF'}
            </Button>
          </div>
        </form>
      </section>

      <section className="panel-card">
        <h2>Rangos cargados</h2>
        {rangos.length === 0 ? (
          <p className="placeholder">No hay rangos de folios cargados para esta empresa.</p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table data-table--interactive">
              <thead>
                <tr>
                  <th>Tipo</th>
                  <th>Rango</th>
                  <th>Disponibles</th>
                  <th>Usados</th>
                  <th>Total</th>
                  <th>F. autorización</th>
                  <th>F. subida</th>
                  <th>Archivo</th>
                  <th>Acción</th>
                </tr>
              </thead>
              <tbody>
                {rangos.map((rango) => (
                  <tr
                    key={rango.id}
                    {...buildInteractiveRowProps({
                      rowId: rango.id,
                      isSelected: rowSelection.isSelected(rango.id),
                      onSelect: rowSelection.select,
                    })}
                  >
                    <td>
                      {rango.tipo_documento.codigo}
                      {rango.tipo_documento.nombre ? (
                        <>
                          <br />
                          <span className="text-muted">{rango.tipo_documento.nombre}</span>
                        </>
                      ) : null}
                    </td>
                    <td>{formatRangoFolios(rango.rango)}</td>
                    <td>{rango.folios.disponibles}</td>
                    <td>{rango.folios.usados}</td>
                    <td>{rango.folios.total}</td>
                    <td>{formatFechaRango(rango.fecha_autorizacion)}</td>
                    <td>{formatFechaRango(rango.fecha_subida)}</td>
                    <td>{rango.archivo}</td>
                    <td
                      className="data-table__actions"
                      onClick={stopRowClickPropagation}
                    >
                      <Button
                        variant="secondary"
                        disabled={!puedeEliminarRango(rango)}
                        onClick={() => openRemoveModal(rango)}
                      >
                        Eliminar
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
        isOpen={rangoToRemove !== null}
        title="Eliminar rango de folios"
        confirmLabel="Eliminar"
        variant="danger"
        isLoading={isRemoving}
        error={removeError}
        onConfirm={confirmRemove}
        onCancel={closeRemoveModal}
      >
        <p>
          ¿Está seguro de eliminar el rango{' '}
          <strong>
            {rangoToRemove?.tipo_documento.codigo} ({rangoToRemove ? formatRangoFolios(rangoToRemove.rango) : ''})
          </strong>
          ?
        </p>
        {rangoToRemove && !puedeEliminarRango(rangoToRemove) ? (
          <p>No se puede eliminar porque tiene folios usados en documentos emitidos.</p>
        ) : (
          <p>Se eliminarán todos los folios asociados a este rango.</p>
        )}
      </ConfirmDialog>
    </AppLayout>
  )
}
