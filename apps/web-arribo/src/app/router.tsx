import { Navigate, Route, Routes } from 'react-router-dom'
import { LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { ProtectedRoute } from '@/features/auth/components/ProtectedRoute'
import { RoleProtectedRoute } from '@/features/auth/components/RoleProtectedRoute'
import { EmpresaAccessProtectedRoute } from '@/features/auth/components/EmpresaAccessProtectedRoute'
import { LoginPage } from '@/features/auth/components/LoginPage'
import { DashboardPage } from '@/features/dashboard/components/DashboardPage'
import { EmpresasPage } from '@/features/empresas/components/EmpresasPage'
import { EmpresaActecosPage } from '@/features/empresas/components/EmpresaActecosPage'
import { EmpresaCertificadosPage } from '@/features/empresas/components/EmpresaCertificadosPage'
import { EmpresaPersonasAutorizadasPage } from '@/features/empresas/components/EmpresaPersonasAutorizadasPage'
import { EmpresaTiposDocumentosPage } from '@/features/empresas/components/EmpresaTiposDocumentosPage'
import { EmpresaRangosFoliosPage } from '@/features/empresas/components/EmpresaRangosFoliosPage'
import { ImpuestosPage } from '@/features/impuestos/components/ImpuestosPage'
import { UsuariosPage } from '@/features/usuarios/components/UsuariosPage'

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
      <Route
        path="/empresas"
        element={
          <ProtectedRoute>
            <EmpresaAccessProtectedRoute>
              <EmpresasPage />
            </EmpresaAccessProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/empresas/:id/actecos"
        element={
          <ProtectedRoute>
            <EmpresaAccessProtectedRoute>
              <EmpresaActecosPage />
            </EmpresaAccessProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/empresas/:id/personas-autorizadas"
        element={
          <ProtectedRoute>
            <EmpresaAccessProtectedRoute>
              <EmpresaPersonasAutorizadasPage />
            </EmpresaAccessProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/empresas/:id/certificados"
        element={
          <ProtectedRoute>
            <RoleProtectedRoute>
              <EmpresaCertificadosPage />
            </RoleProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/empresas/:id/tipos-documentos"
        element={
          <ProtectedRoute>
            <EmpresaAccessProtectedRoute>
              <EmpresaTiposDocumentosPage />
            </EmpresaAccessProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/empresas/:id/rangos-folios"
        element={
          <ProtectedRoute>
            <EmpresaAccessProtectedRoute>
              <EmpresaRangosFoliosPage />
            </EmpresaAccessProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/impuestos"
        element={
          <ProtectedRoute>
            <RoleProtectedRoute>
              <ImpuestosPage />
            </RoleProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route
        path="/usuarios"
        element={
          <ProtectedRoute>
            <RoleProtectedRoute>
              <UsuariosPage />
            </RoleProtectedRoute>
          </ProtectedRoute>
        }
      />
      <Route path="/" element={<HomeRedirect />} />
      <Route path="*" element={<HomeRedirect />} />
    </Routes>
  )
}
