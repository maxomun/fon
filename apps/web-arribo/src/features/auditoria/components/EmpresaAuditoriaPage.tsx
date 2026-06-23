import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert } from '@/components/ui'
import { AuditoriaDetalleModal } from '@/features/auditoria/components/AuditoriaDetalleModal'
import { AuditoriaFilters } from '@/features/auditoria/components/AuditoriaFilters'
import { AuditoriaPagination } from '@/features/auditoria/components/AuditoriaPagination'
import { AuditoriaTable } from '@/features/auditoria/components/AuditoriaTable'
import { useAuditoriaList } from '@/features/auditoria/hooks/useAuditoriaList'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import { ApiError } from '@/services/apiClient'

export function EmpresaAuditoriaPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)

  const {
    eventos,
    meta,
    filtros,
    page,
    setPage,
    updateFiltros,
    isLoading,
    listError,
    detalleEvento,
    isDetalleOpen,
    isDetalleLoading,
    detalleError,
    openDetalle,
    closeDetalle,
  } = useAuditoriaList({ mode: 'empresa', empresaId })

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

  return (
    <AppLayout>
      <p className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
      </p>

      <div className="page-header">
        <div>
          <h1>Auditoría de empresa</h1>
          <p className="page-header__subtitle">
            {empresa
              ? `${empresa.razon_social} — acciones registradas en esta empresa.`
              : 'Eventos de auditoría asociados a la empresa.'}
          </p>
        </div>
      </div>

      {pageError ? <Alert variant="error">{pageError}</Alert> : null}
      {listError ? <Alert variant="error">{listError}</Alert> : null}

      <AuditoriaFilters filtros={filtros} onChange={updateFiltros} />

      {isLoading ? (
        <p className="page-loading">Cargando eventos…</p>
      ) : eventos.length === 0 ? (
        <p className="page-empty">No hay eventos que coincidan con los filtros.</p>
      ) : (
        <>
          <AuditoriaTable eventos={eventos} onVerDetalle={(evento) => void openDetalle(evento)} />
          <AuditoriaPagination meta={meta} page={page} onPageChange={setPage} />
        </>
      )}

      <AuditoriaDetalleModal
        evento={detalleEvento}
        isOpen={isDetalleOpen}
        isLoading={isDetalleLoading}
        error={detalleError}
        onClose={closeDetalle}
      />
    </AppLayout>
  )
}
