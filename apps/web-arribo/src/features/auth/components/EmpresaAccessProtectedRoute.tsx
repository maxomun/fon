import { Navigate } from 'react-router-dom'
import { LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { canAccessEmpresasModule } from '@/features/auth/utils/roles'
import type { ReactNode } from 'react'

interface EmpresaAccessProtectedRouteProps {
  children: ReactNode
}

export function EmpresaAccessProtectedRoute({ children }: EmpresaAccessProtectedRouteProps) {
  const { user, isLoading } = useAuth()

  if (isLoading) {
    return <LoadingScreen message="Verificando sesión…" />
  }

  if (!canAccessEmpresasModule(user)) {
    return <Navigate to="/dashboard" replace />
  }

  return children
}
