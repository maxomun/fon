import type { UserProfile } from '@/features/auth/types/auth.types'

export const ROL_ADMINISTRADOR_FON = 'administrador_fon'

export function hasRole(user: UserProfile | null, codigo: string): boolean {
  return user?.roles.some((rol) => rol.codigo === codigo) ?? false
}

export function isAdministradorFon(user: UserProfile | null): boolean {
  return hasAccesoGlobal(user)
}

export function hasAccesoGlobal(user: UserProfile | null): boolean {
  return user?.acceso_global === true || hasRole(user, ROL_ADMINISTRADOR_FON)
}

export function getEmpresas(user: UserProfile | null) {
  return user?.empresas ?? []
}

export function getEmpresasAdministrables(user: UserProfile | null) {
  if (hasAccesoGlobal(user)) {
    return getEmpresas(user)
  }

  return getEmpresas(user).filter((empresa) => empresa.es_administrador)
}

export function canAccessEmpresasModule(user: UserProfile | null): boolean {
  return hasAccesoGlobal(user) || getEmpresasAdministrables(user).length > 0
}

export function canAdministrarEmpresa(user: UserProfile | null, empresaId: number): boolean {
  if (hasAccesoGlobal(user)) {
    return true
  }

  return getEmpresas(user).some(
    (empresa) => empresa.id === empresaId && empresa.es_administrador,
  )
}

export function displayUserName(user: UserProfile | null): string {
  return user?.nombre_completo ?? user?.username ?? user?.email ?? ''
}

export function formatRoles(user: UserProfile | null): string {
  if (!user?.roles.length) {
    return ''
  }

  return user.roles.map((rol) => rol.descripcion || rol.codigo).join(', ')
}
