import { useCallback, useEffect, useState } from 'react'
import { auditoriaService } from '@/features/auditoria/services/auditoriaService'
import type {
  AuditEventDetail,
  AuditEventListMeta,
  AuditEventSummary,
  AuditoriaFiltros,
} from '@/features/auditoria/types/auditEvent.types'
import { emptyAuditoriaFiltros } from '@/features/auditoria/types/auditEvent.types'
import { ApiError } from '@/services/apiClient'

type AuditoriaScope =
  | { mode: 'global' }
  | { mode: 'empresa'; empresaId: number }

export function useAuditoriaList(scope: AuditoriaScope) {
  const mode = scope.mode
  const empresaId = scope.mode === 'empresa' ? scope.empresaId : null

  const [eventos, setEventos] = useState<AuditEventSummary[]>([])
  const [meta, setMeta] = useState<AuditEventListMeta | null>(null)
  const [filtros, setFiltros] = useState<AuditoriaFiltros>(emptyAuditoriaFiltros())
  const [page, setPage] = useState(1)
  const [isLoading, setIsLoading] = useState(true)
  const [listError, setListError] = useState<string | null>(null)

  const [detalleEvento, setDetalleEvento] = useState<AuditEventDetail | null>(null)
  const [isDetalleOpen, setIsDetalleOpen] = useState(false)
  const [isDetalleLoading, setIsDetalleLoading] = useState(false)
  const [detalleError, setDetalleError] = useState<string | null>(null)

  const loadEventos = useCallback(async () => {
    setListError(null)
    setIsLoading(true)

    try {
      const response =
        mode === 'global'
          ? await auditoriaService.listGlobal(filtros, page)
          : await auditoriaService.listEmpresa(empresaId!, filtros, page)

      setEventos(response.data)
      setMeta(response.meta)
    } catch (error) {
      setEventos([])
      setMeta(null)
      setListError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar los eventos de auditoría',
      )
    } finally {
      setIsLoading(false)
    }
  }, [filtros, page, mode, empresaId])

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadEventos()
    }, 300)

    return () => window.clearTimeout(timeout)
  }, [loadEventos])

  function updateFiltros(partial: Partial<AuditoriaFiltros>) {
    setPage(1)
    setFiltros((current) => ({ ...current, ...partial }))
  }

  async function openDetalle(evento: AuditEventSummary) {
    setDetalleEvento(null)
    setIsDetalleOpen(true)
    setDetalleError(null)
    setIsDetalleLoading(true)

    try {
      const response =
        mode === 'global'
          ? await auditoriaService.getGlobal(evento.id)
          : await auditoriaService.getEmpresa(empresaId!, evento.id)

      setDetalleEvento(response.data)
    } catch (error) {
      setDetalleError(
        error instanceof ApiError ? error.message : 'No se pudo cargar el detalle del evento',
      )
    } finally {
      setIsDetalleLoading(false)
    }
  }

  function closeDetalle() {
    setIsDetalleOpen(false)
    setDetalleEvento(null)
    setDetalleError(null)
  }

  return {
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
  }
}
