import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import {
  applyPageMeta,
  buildPageTitle,
  extractEmpresaIdFromPath,
  resolveRouteMeta,
} from '@/config/pageMeta'
import { empresasService } from '@/features/empresas/services/empresasService'
import {
  getCachedEmpresaNombre,
  setCachedEmpresaNombre,
} from '@/features/empresas/services/empresaPageMetaCache'

export function DocumentMeta() {
  const { pathname } = useLocation()

  useEffect(() => {
    const route = resolveRouteMeta(pathname)
    const empresaId = extractEmpresaIdFromPath(pathname)

    function apply(sectionTitle: string, empresaNombre?: string | null) {
      applyPageMeta({
        title: buildPageTitle(sectionTitle, empresaNombre),
        favicon: route.favicon,
      })
    }

    if (!empresaId) {
      apply(route.sectionTitle)
      return
    }

    const cached = getCachedEmpresaNombre(empresaId)
    if (cached) {
      apply(route.sectionTitle, cached)
      return
    }

    apply(route.sectionTitle)

    let cancelled = false

    void empresasService
      .get(empresaId)
      .then((response) => {
        if (cancelled) {
          return
        }

        const nombre = response.data.razon_social
        setCachedEmpresaNombre(empresaId, nombre)
        apply(route.sectionTitle, nombre)
      })
      .catch(() => {
        // Sin empresa en título si falla la carga (permisos, sesión, etc.)
      })

    return () => {
      cancelled = true
    }
  }, [pathname])

  return null
}
