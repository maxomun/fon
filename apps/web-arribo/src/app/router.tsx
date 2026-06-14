import { Navigate, Route, Routes } from 'react-router-dom'
import { LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { ProtectedRoute } from '@/features/auth/components/ProtectedRoute'
import { LoginPage } from '@/features/auth/components/LoginPage'
import { DashboardPage } from '@/features/dashboard/components/DashboardPage'

function HomeRedirect() {
  const { isAuthenticated, isLoading } = useAuth()

  if (isLoading) {
    return <LoadingScreen message="Verificando sesión…" />
  }

  return (
    <Navigate to={isAuthenticated ? '/dashboard' : '/login'} replace />
  )
}

export function AppRouter() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <DashboardPage />
          </ProtectedRoute>
        }
      />
      <Route path="/" element={<HomeRedirect />} />
      <Route path="*" element={<HomeRedirect />} />
    </Routes>
  )
}
