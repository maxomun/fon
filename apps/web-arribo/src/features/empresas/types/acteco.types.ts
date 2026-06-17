export interface GrupoActeco {
  id: number
  nombre: string
}

export interface Acteco {
  id: number
  codigo: string
  nombre: string
  afecto_iva: boolean
  grupo_acteco: GrupoActeco
}

export interface ActecosListResponse {
  success: boolean
  data: Acteco[]
  message?: string
}

export interface ActecoResponse {
  success: boolean
  data: Acteco
  message?: string
}

export interface ActecoDeleteResponse {
  success: boolean
  message?: string
}
