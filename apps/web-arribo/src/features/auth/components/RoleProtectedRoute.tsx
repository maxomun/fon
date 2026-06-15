import { Navigate } from 'react-router-dom'
import { LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { isAdministradorFon } from '@/features/auth/utils/roles'
import type { ReactNode } from 'react'

interface RoleProtectedRouteProps {
  children: ReactNode
}

export function RoleProtectedRoute({ children }: RoleProtectedRouteProps) {
  const { user, isLoading } = useAuth()

  if (isLoading) {
    return <LoadingScreen message="Verificando sesión…" />
  }

  if (!isAdministradorFon(user)) {
    return <Navigate to="/dashboard" replace />
  }

  return children
}
