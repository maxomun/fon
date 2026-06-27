import { matchPath } from 'react-router-dom'

export const APP_TITLE = 'FacturaOn'

/** Máximo visible para razón social en la pestaña del navegador. */
export const EMPRESA_TAB_MAX_LENGTH = 20

export const favicons = {
  default: '/favicons/favicon-default.png',
  emitir: '/favicons/favicon-emitir.png',
  documentos: '/favicons/favicon-documentos.png',
  login: '/favicons/favicon-login.png',
  admin: '/favicons/favicon-admin.png',
} as const

export type FaviconKey = keyof typeof favicons

export interface PageMeta {
  title: string
  favicon: string
}

export interface ResolvedRouteMeta {
  sectionTitle: string
  favicon: string
}

type MetaRule = {
  path: string
  title: string
  favicon: FaviconKey
}

const metaRules: MetaRule[] = [
  { path: '/empresas/:id/emitir/nuevo', title: 'Emitir FE 33', favicon: 'emitir' },
  { path: '/empresas/:id/emitir', title: 'Emitir DTE', favicon: 'emitir' },
  { path: '/empresas/:id/documentos', title: 'Documentos emitidos', favicon: 'documentos' },
  { path: '/empresas/:id/auditoria', title: 'Auditoría de empresa', favicon: 'admin' },
  { path: '/empresas/:id/certificados', title: 'Certificados', favicon: 'admin' },
  { path: '/auditoria', title: 'Auditoría', favicon: 'admin' },
  { path: '/usuarios', title: 'Usuarios', favicon: 'admin' },
  { path: '/impuestos', title: 'Impuestos', favicon: 'admin' },
  { path: '/login', title: 'Iniciar sesión', favicon: 'login' },
  { path: '/onboarding/verificar-email', title: 'Verificar correo', favicon: 'login' },
  { path: '/onboarding/establecer-password', title: 'Establecer contraseña', favicon: 'login' },
  { path: '/olvide-contrasena/confirmar', title: 'Contraseña actualizada', favicon: 'login' },
  { path: '/olvide-contrasena', title: 'Recuperar contraseña', favicon: 'login' },
  { path: '/dashboard', title: 'Panel', favicon: 'default' },
  { path: '/empresas', title: 'Empresas', favicon: 'default' },
  { path: '/empresas/:id/productos', title: 'Productos', favicon: 'default' },
  { path: '/empresas/:id/actecos', title: 'Actividades económicas', favicon: 'default' },
  { path: '/empresas/:id/tipos-documentos', title: 'Tipos de documento', favicon: 'default' },
  { path: '/empresas/:id/rangos-folios', title: 'Rangos de folios', favicon: 'default' },
  { path: '/empresas/:id/personas-autorizadas', title: 'Personas autorizadas', favicon: 'default' },
]

const defaultRouteMeta: ResolvedRouteMeta = {
  sectionTitle: 'Arribo',
  favicon: favicons.default,
}

export function truncateForTabLabel(text: string, maxLength = EMPRESA_TAB_MAX_LENGTH) {
  const trimmed = text.trim().replace(/\s+/g, ' ')
  if (trimmed.length <= maxLength) {
    return trimmed
  }

  return `${trimmed.slice(0, maxLength - 1).trimEnd()}…`
}

export function buildPageTitle(sectionTitle: string, empresaNombre?: string | null) {
  const section = sectionTitle.trim()

  if (empresaNombre?.trim()) {
    return `${section} · ${truncateForTabLabel(empresaNombre)} · ${APP_TITLE}`
  }

  return `${section} · ${APP_TITLE}`
}

export function extractEmpresaIdFromPath(pathname: string): number | null {
  const match = pathname.match(/^\/empresas\/(\d+)(?:\/|$)/)
  if (!match) {
    return null
  }

  const empresaId = Number(match[1])
  return Number.isFinite(empresaId) && empresaId > 0 ? empresaId : null
}

export function resolveRouteMeta(pathname: string): ResolvedRouteMeta {
  for (const rule of metaRules) {
    const match = matchPath({ path: rule.path, end: true }, pathname)
    if (match) {
      return {
        sectionTitle: rule.title,
        favicon: favicons[rule.favicon],
      }
    }
  }

  return defaultRouteMeta
}

/** @deprecated Usar resolveRouteMeta + buildPageTitle */
export function formatPageTitle(pageTitle: string) {
  return buildPageTitle(pageTitle)
}

export function resolvePageMeta(pathname: string): PageMeta {
  const route = resolveRouteMeta(pathname)
  return {
    title: buildPageTitle(route.sectionTitle),
    favicon: route.favicon,
  }
}

function ensureFaviconLink() {
  let link = document.querySelector<HTMLLinkElement>("link[rel='icon']")
  if (!link) {
    link = document.createElement('link')
    link.rel = 'icon'
    document.head.appendChild(link)
  }
  return link
}

export function applyPageMeta(meta: PageMeta) {
  document.title = meta.title
  const link = ensureFaviconLink()
  link.type = 'image/png'
  link.href = meta.favicon
}
