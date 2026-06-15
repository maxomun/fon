import { AppLayout } from '@/components/layout/AppLayout'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { formatRoles } from '@/features/auth/utils/roles'

export function DashboardPage() {
  const { user } = useAuth()

  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p className="page-header__subtitle">
            {user?.persona?.nombre_completo ?? user?.email}, has iniciado sesión
            correctamente.
          </p>
        </div>
      </div>

      <section className="panel-card">
        <h2>Bienvenido</h2>
        {user?.empresa ? (
          <p className="dashboard-meta">Empresa: {user.empresa}</p>
        ) : null}
        {user?.roles.length ? (
          <p className="dashboard-meta">Roles: {formatRoles(user)}</p>
        ) : null}
      </section>
    </AppLayout>
  )
}
