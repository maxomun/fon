import { Navigate, useParams } from 'react-router-dom'
import { LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { canAdministrarEmpresa } from '@/features/auth/utils/roles'
import type { ReactNode } from 'react'

interface EmpresaAdminProtectedRouteProps {
  children: ReactNode
}

export function EmpresaAdminProtectedRoute({ children }: EmpresaAdminProtectedRouteProps) {
  const { user, isLoading } = useAuth()
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  if (isLoading) {
    return <LoadingScreen message="Verificando sesión…" />
  }

  if (!Number.isFinite(empresaId) || empresaId <= 0 || !canAdministrarEmpresa(user, empresaId)) {
    return <Navigate to="/dashboard" replace />
  }

  return children
}
