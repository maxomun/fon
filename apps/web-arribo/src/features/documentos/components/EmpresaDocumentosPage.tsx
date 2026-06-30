import { useCallback, useEffect, useState } from 'react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDialog, LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { hasAccesoGlobal } from '@/features/auth/utils/roles'
import { DocumentoArchivoPreviewModal } from '@/features/documentos/components/DocumentoArchivoPreviewModal'
import { DocumentoDetalleModal } from '@/features/documentos/components/DocumentoDetalleModal'
import { DocumentosPagination } from '@/features/documentos/components/DocumentosPagination'
import { DocumentosTable } from '@/features/documentos/components/DocumentosTable'
import { useDocumentosList } from '@/features/documentos/hooks/useDocumentosList'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import { ApiError } from '@/services/apiClient'

export function EmpresaDocumentosPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)
  const { user } = useAuth()
  const isFonAdmin = hasAccesoGlobal(user)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [envioALimpiar, setEnvioALimpiar] = useState<number | null>(null)
  const [confirmarLimpiarTodos, setConfirmarLimpiarTodos] = useState(false)

  const {
    documentos,
    meta,
    query,
    page,
    setPage,
    updateQuery,
    isLoading,
    listError,
    detalleDocumento,
    isDetalleOpen,
    isDetalleLoading,
    detalleError,
    openDetalle,
    closeDetalle,
    downloadXml,
    downloadPdf,
    previewPdf,
    previewXml,
    previewTarget,
    closePreview,
    downloadingEnvioId,
    downloadingPdfDocumentoId,
    downloadError,
    limpiarEnvio,
    limpiarTodosEnvios,
    limpiandoEnvioId,
    isLimpiandoTodos,
    limpiezaError,
    limpiezaMensaje,
  } = useDocumentosList(empresaId)

  const loadEmpresa = useCallback(async () => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      setPageError('Empresa no válida')
      return
    }

    setPageError(null)

    try {
      const response = await empresasService.get(empresaId)
      setEmpresa(response.data)
    } catch (error) {
      setPageError(
        error instanceof ApiError ? error.message : 'No se pudo cargar la empresa',
      )
    }
  }, [empresaId])

  useEffect(() => {
    void loadEmpresa()
  }, [loadEmpresa])

  async function confirmarLimpiarEnvio() {
    if (!envioALimpiar) {
      return
    }

    await limpiarEnvio(envioALimpiar)
    setEnvioALimpiar(null)
  }

  async function confirmarLimpiarTodosEnvios() {
    await limpiarTodosEnvios()
    setConfirmarLimpiarTodos(false)
  }

  if (!Number.isFinite(empresaId) || empresaId <= 0) {
    return <Navigate to="/empresas" replace />
  }

  return (
    <AppLayout>
      <p className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
      </p>

      <div className="page-header">
        <div>
          <h1>Documentos emitidos</h1>
          <p className="page-header__subtitle">
            {empresa
              ? `${empresa.razon_social} — DTE timbrados desde la plataforma.`
              : 'Historial de documentos tributarios electrónicos emitidos.'}
          </p>
        </div>
        <Link className="emision-checklist__link" to={`/empresas/${empresaId}/emitir`}>
          Ir a emitir
        </Link>
      </div>

      {pageError ? <Alert variant="error">{pageError}</Alert> : null}
      {listError ? <Alert variant="error">{listError}</Alert> : null}
      {downloadError ? <Alert variant="error">{downloadError}</Alert> : null}
      {limpiezaError ? <Alert variant="error">{limpiezaError}</Alert> : null}
      {limpiezaMensaje ? <Alert variant="success">{limpiezaMensaje}</Alert> : null}

      {isFonAdmin ? (
        <section className="panel-card documentos-admin-panel">
          <h2>Limpieza de pruebas (administrador FON)</h2>
          <p className="documentos-admin-panel__intro">
            Elimina envíos DTE de certificación, borra los documentos asociados y libera los folios
            CAF para volver a emitir. Solo aplica a emisiones autónomas sin notas de crédito o
            débito asociadas.
          </p>
          <Button
            type="button"
            className="btn-danger"
            disabled={isLimpiandoTodos || isLoading || (meta?.total_count ?? 0) === 0}
            onClick={() => setConfirmarLimpiarTodos(true)}
          >
            {isLimpiandoTodos ? 'Limpiando envíos…' : 'Limpiar todos los envíos'}
          </Button>
        </section>
      ) : null}

      <section className="panel-card">
        <div className="documentos-filters">
          <label className="documentos-filters__label" htmlFor="documentos-buscar">
            Buscar
          </label>
          <input
            id="documentos-buscar"
            type="search"
            className="documentos-filters__input"
            placeholder="Folio, RUT o razón social del receptor"
            value={query}
            onChange={(event) => updateQuery(event.target.value)}
          />
        </div>

        {isLoading ? (
          <LoadingScreen message="Cargando documentos…" />
        ) : documentos.length === 0 ? (
          <p className="placeholder">
            {query.trim()
              ? 'No hay documentos que coincidan con la búsqueda.'
              : 'Aún no hay documentos emitidos para esta empresa.'}
          </p>
        ) : (
          <>
            <DocumentosTable
              documentos={documentos}
              downloadingEnvioId={downloadingEnvioId}
              downloadingPdfDocumentoId={downloadingPdfDocumentoId}
              limpiandoEnvioId={limpiandoEnvioId}
              isFonAdmin={isFonAdmin}
              onVerDetalle={(documento) => void openDetalle(documento)}
              onPreviewPdf={(documento) => previewPdf(documento, empresa?.rut)}
              onDownloadXml={(documento) =>
                void downloadXml(documento.dte_envio_id!, {
                  tipo_documento: documento.tipo_documento,
                  folio: documento.folio,
                  rut_emisor: empresa?.rut,
                })
              }
              onPreviewXml={(documento) =>
                previewXml(documento, documento.dte_envio_id!, empresa?.rut)
              }
              onLimpiarEnvio={(dteEnvioId) => setEnvioALimpiar(dteEnvioId)}
            />
            <DocumentosPagination meta={meta} page={page} onPageChange={setPage} />
          </>
        )}
      </section>

      <DocumentoDetalleModal
        empresaId={empresaId}
        documento={detalleDocumento}
        isOpen={isDetalleOpen}
        isLoading={isDetalleLoading}
        error={detalleError}
        downloadingEnvioId={downloadingEnvioId}
        downloadingPdfDocumentoId={downloadingPdfDocumentoId}
        limpiandoEnvioId={limpiandoEnvioId}
        isFonAdmin={isFonAdmin}
        onClose={closeDetalle}
        onDownloadPdf={(documento) => void downloadPdf(documento)}
        onPreviewPdf={(documento) => previewPdf(documento, documento.rut_emisor)}
        onPreviewXml={(documento) =>
          previewXml(documento, documento.dte_envio_id!, documento.rut_emisor)
        }
        onDownloadXml={(documento) =>
          void downloadXml(documento.dte_envio_id!, {
            tipo_documento: documento.tipo_documento,
            folio: documento.folio,
            rut_emisor: documento.rut_emisor,
          })
        }
        onLimpiarEnvio={(dteEnvioId) => setEnvioALimpiar(dteEnvioId)}
      />

      <DocumentoArchivoPreviewModal
        empresaId={empresaId}
        target={previewTarget}
        onClose={closePreview}
      />

      <ConfirmDialog
        isOpen={envioALimpiar !== null}
        title={`Limpiar envío #${envioALimpiar ?? ''}`}
        variant="danger"
        confirmLabel="Limpiar envío"
        isLoading={limpiandoEnvioId === envioALimpiar}
        error={limpiezaError}
        onCancel={() => setEnvioALimpiar(null)}
        onConfirm={() => void confirmarLimpiarEnvio()}
      >
        <p>
          Se eliminarán el XML archivado, los documentos emitidos de este envío y se liberarán los
          folios CAF usados. Esta acción es irreversible.
        </p>
      </ConfirmDialog>

      <ConfirmDialog
        isOpen={confirmarLimpiarTodos}
        title="Limpiar todos los envíos de prueba"
        variant="danger"
        confirmLabel="Limpiar todos"
        isLoading={isLimpiandoTodos}
        error={limpiezaError}
        onCancel={() => setConfirmarLimpiarTodos(false)}
        onConfirm={() => void confirmarLimpiarTodosEnvios()}
      >
        <p>
          Se eliminarán todos los envíos DTE de esta empresa que puedan limpiarse (emisiones
          autónomas sin referencias). Los folios quedarán disponibles para repetir la certificación.
        </p>
      </ConfirmDialog>
    </AppLayout>
  )
}
