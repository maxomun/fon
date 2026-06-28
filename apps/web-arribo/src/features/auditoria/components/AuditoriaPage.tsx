import { useEffect, useState } from 'react'
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

export function AuditoriaPage() {
  const [empresas, setEmpresas] = useState<Empresa[]>([])
  const [isLoadingEmpresas, setIsLoadingEmpresas] = useState(true)
  const [empresasError, setEmpresasError] = useState<string | null>(null)

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
  } = useAuditoriaList({ mode: 'global' })

  useEffect(() => {
    let cancelled = false

    async function loadEmpresas() {
      setIsLoadingEmpresas(true)
      setEmpresasError(null)

      try {
        const response = await empresasService.list()
        if (!cancelled) {
          setEmpresas(response.data)
        }
      } catch (error) {
        if (!cancelled) {
          setEmpresas([])
          setEmpresasError(
            error instanceof ApiError ? error.message : 'No se pudieron cargar las empresas',
          )
        }
      } finally {
        if (!cancelled) {
          setIsLoadingEmpresas(false)
        }
      }
    }

    void loadEmpresas()

    return () => {
      cancelled = true
    }
  }, [])

  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Auditoría</h1>
          <p className="page-header__subtitle">
            Registro de acciones en la plataforma: autenticación, usuarios, empresas, certificados,
            folios y emisión DTE.
          </p>
        </div>
      </div>

      {listError ? <Alert variant="error">{listError}</Alert> : null}
      {empresasError ? <Alert variant="error">{empresasError}</Alert> : null}

      <AuditoriaFilters
        filtros={filtros}
        showEmpresaFilter
        empresas={empresas}
        isLoadingEmpresas={isLoadingEmpresas}
        onChange={updateFiltros}
      />

      {isLoading ? (
        <p className="page-loading">Cargando eventos…</p>
      ) : eventos.length === 0 ? (
        <p className="page-empty">No hay eventos que coincidan con los filtros.</p>
      ) : (
        <>
          <AuditoriaTable
            eventos={eventos}
            showEmpresaColumn
            onVerDetalle={(evento) => void openDetalle(evento)}
          />
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
