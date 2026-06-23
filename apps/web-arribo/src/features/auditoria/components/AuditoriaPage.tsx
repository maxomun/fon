import { AppLayout } from '@/components/layout/AppLayout'
import { Alert } from '@/components/ui'
import { AuditoriaDetalleModal } from '@/features/auditoria/components/AuditoriaDetalleModal'
import { AuditoriaFilters } from '@/features/auditoria/components/AuditoriaFilters'
import { AuditoriaPagination } from '@/features/auditoria/components/AuditoriaPagination'
import { AuditoriaTable } from '@/features/auditoria/components/AuditoriaTable'
import { useAuditoriaList } from '@/features/auditoria/hooks/useAuditoriaList'

export function AuditoriaPage() {
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

      <AuditoriaFilters
        filtros={filtros}
        showEmpresaFilter
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
