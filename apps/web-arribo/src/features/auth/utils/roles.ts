import type { UserProfile } from '@/features/auth/types/auth.types'

export const ROL_ADMINISTRADOR_FON = 'administrador_fon'

export function hasRole(user: UserProfile | null, codigo: string): boolean {
  return user?.roles.some((rol) => rol.codigo === codigo) ?? false
}

export function isAdministradorFon(user: UserProfile | null): boolean {
  return hasRole(user, ROL_ADMINISTRADOR_FON)
}

export function formatRoles(user: UserProfile | null): string {
  if (!user?.roles.length) {
    return ''
  }

  return user.roles.map((rol) => rol.descripcion || rol.codigo).join(', ')
}
