export interface AuditEventActor {
  user_id: number | null
  email: string | null
  nombre: string | null
  acceso_global: boolean | null
}

export interface AuditEventEmpresa {
  id: number
  rut?: string
  razon_social?: string
}

export interface AuditEventRecurso {
  tipo: string | null
  id: string | null
  label: string | null
}

export interface AuditEventSummary {
  id: number
  accion: string
  accion_label: string
  categoria: string
  resultado: 'success' | 'failure'
  actor: AuditEventActor
  empresa: AuditEventEmpresa | null
  recurso: AuditEventRecurso | null
  created_at: string
}

export interface AuditEventDetail extends AuditEventSummary {
  cambios: Record<string, unknown>
  metadata: Record<string, unknown>
  codigo_error: string | null
  mensaje: string | null
  ip: string | null
  user_agent: string | null
  request_id: string | null
}

export interface AuditEventListMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

export interface AuditEventListResponse {
  success: boolean
  data: AuditEventSummary[]
  meta: AuditEventListMeta
}

export interface AuditEventDetailResponse {
  success: boolean
  data: AuditEventDetail
}

export interface AuditoriaFiltros {
  q: string
  categoria: string
  resultado: '' | 'success' | 'failure'
  desde: string
  hasta: string
  empresa_id: string
}

/** Valor enviado a la API para eventos sin empresa asociada (login FON, etc.). */
export const AUDITORIA_EMPRESA_SIN_ASIGNAR = 'sin_empresa'

export const CATEGORIA_OPCIONES = [
  { value: '', label: 'Todas las categorías' },
  { value: 'auth', label: 'Autenticación' },
  { value: 'usuarios', label: 'Usuarios' },
  { value: 'personas', label: 'Personas autorizadas' },
  { value: 'empresa', label: 'Empresa' },
  { value: 'certificados', label: 'Certificados' },
  { value: 'folios', label: 'Folios' },
  { value: 'dte', label: 'DTE' },
  { value: 'productos', label: 'Productos' },
  { value: 'catalogo', label: 'Catálogo' },
] as const

export const RESULTADO_OPCIONES = [
  { value: '', label: 'Todos' },
  { value: 'success', label: 'Éxito' },
  { value: 'failure', label: 'Fallo' },
] as const

export function emptyAuditoriaFiltros(): AuditoriaFiltros {
  return {
    q: '',
    categoria: '',
    resultado: '',
    desde: '',
    hasta: '',
    empresa_id: '',
  }
}

export function formatAuditDateTime(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleString('es-CL', {
    dateStyle: 'short',
    timeStyle: 'short',
  })
}

export function actorLabel(actor: AuditEventActor) {
  if (actor.nombre?.trim()) {
    return actor.nombre
  }

  if (actor.email?.trim()) {
    return actor.email
  }

  return '—'
}

export function resultadoLabel(resultado: AuditEventSummary['resultado']) {
  return resultado === 'success' ? 'Éxito' : 'Fallo'
}

export function categoriaLabel(categoria: string) {
  return CATEGORIA_OPCIONES.find((opcion) => opcion.value === categoria)?.label ?? categoria
}

export function formatCambioValor(valor: unknown) {
  if (valor === null || valor === undefined) {
    return '—'
  }

  if (typeof valor === 'object') {
    return JSON.stringify(valor)
  }

  return String(valor)
}
