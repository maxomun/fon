import type { Empresa } from '@/features/empresas/types/empresa.types'
import type { PersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'
import type { TipoHabilitado } from '@/features/empresas/types/tipoHabilitado.types'

export type PrerrequisitoEstado = 'ok' | 'pendiente'

export type PrerrequisitoId =
  | 'productos'
  | 'tipos_documento'
  | 'folios'
  | 'certificado'
  | 'persona_certificado'

export interface PrerrequisitoItem {
  id: PrerrequisitoId
  titulo: string
  mensaje: string
  estado: PrerrequisitoEstado
  linkTo?: string
  linkLabel?: string
  ayudaSinLink?: string
}

export interface PrerrequisitosInput {
  empresaId: number
  empresa: Empresa
  productosActivosCount: number
  tiposHabilitados: TipoHabilitado[]
  personas: PersonaAutorizada[]
}

export interface PrerrequisitosResultado {
  items: PrerrequisitoItem[]
  listoParaEmitir: boolean
  pendientes: number
}
