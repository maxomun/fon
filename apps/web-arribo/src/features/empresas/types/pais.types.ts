export interface Pais {
  id: number
  codigo: string
  nombre: string
  activo: boolean
}

export interface PaisesListResponse {
  success: boolean
  data: Pais[]
}

export const CODIGO_PAIS_CHILE = 'CL'

export function findPaisChile(paises: Pais[]): Pais | undefined {
  return paises.find((pais) => pais.codigo === CODIGO_PAIS_CHILE)
}
