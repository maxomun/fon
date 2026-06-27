import { useCallback, useEffect, useState } from 'react'
import { empresaPersonasAutorizadasService } from '@/features/empresas/services/empresaPersonasAutorizadasService'
import { empresaTiposHabilitadosService } from '@/features/empresas/services/empresaTiposHabilitadosService'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import { evaluarPrerrequisitos } from '@/features/emision/utils/evaluarPrerrequisitos'
import type { PrerrequisitosResultado } from '@/features/emision/types/prerrequisitos.types'
import { productosService } from '@/features/productos/services/productosService'
import { ApiError } from '@/services/apiClient'

const resultadoInicial: PrerrequisitosResultado = {
  items: [],
  listoParaEmitir: false,
  pendientes: 0,
  advertencias: 0,
}

export function useEmisionPrerrequisitos(empresaId: number) {
  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [resultado, setResultado] = useState<PrerrequisitosResultado>(resultadoInicial)
  const [isLoading, setIsLoading] = useState(true)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [pageError, setPageError] = useState<string | null>(null)

  const load = useCallback(
    async (options?: { silent?: boolean }) => {
      if (!Number.isFinite(empresaId) || empresaId <= 0) {
        setPageError('Empresa no válida')
        setIsLoading(false)
        return
      }

      setPageError(null)

      if (options?.silent) {
        setIsRefreshing(true)
      } else {
        setIsLoading(true)
      }

      try {
        const [empresaResponse, productosResponse, tiposResponse, personasResponse] =
          await Promise.all([
            empresasService.get(empresaId),
            productosService.list(empresaId, '', 'activos', 1),
            empresaTiposHabilitadosService.listAssigned(empresaId),
            empresaPersonasAutorizadasService.listAssigned(empresaId),
          ])

        setEmpresa(empresaResponse.data)
        setResultado(
          evaluarPrerrequisitos({
            empresaId,
            empresa: empresaResponse.data,
            productosActivosCount: productosResponse.meta.total_count,
            tiposHabilitados: tiposResponse.data,
            personas: personasResponse.data,
          }),
        )
      } catch (error) {
        const message =
          error instanceof ApiError
            ? error.message
            : 'No se pudieron cargar los prerrequisitos de emisión.'
        setPageError(message)
        setResultado(resultadoInicial)
      } finally {
        setIsLoading(false)
        setIsRefreshing(false)
      }
    },
    [empresaId],
  )

  useEffect(() => {
    void load()
  }, [load])

  return {
    empresa,
    resultado,
    isLoading,
    isRefreshing,
    pageError,
    reload: () => load({ silent: true }),
  }
}
