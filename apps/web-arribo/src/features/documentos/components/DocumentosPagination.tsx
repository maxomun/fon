import { Button } from '@/components/ui'
import type { DocumentosListMeta } from '@/features/documentos/types/documentoEmitido.types'

interface DocumentosPaginationProps {
  meta: DocumentosListMeta | null
  page: number
  onPageChange: (page: number) => void
}

export function DocumentosPagination({ meta, page, onPageChange }: DocumentosPaginationProps) {
  if (!meta || meta.total_count === 0) {
    return null
  }

  const totalPages = Math.max(meta.total_pages, 1)

  return (
    <div className="auditoria-pagination">
      <Button type="button" variant="secondary" disabled={page <= 1} onClick={() => onPageChange(page - 1)}>
        Anterior
      </Button>
      <p className="auditoria-pagination__info">
        Página {meta.current_page} de {totalPages} · {meta.total_count} documento
        {meta.total_count === 1 ? '' : 's'}
      </p>
      <Button
        type="button"
        variant="secondary"
        disabled={page >= totalPages}
        onClick={() => onPageChange(page + 1)}
      >
        Siguiente
      </Button>
    </div>
  )
}
