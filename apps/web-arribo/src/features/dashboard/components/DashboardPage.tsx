import { AppLayout } from '@/components/layout/AppLayout'
import { useAuth } from '@/features/auth/hooks/useAuth'

export function DashboardPage() {
  const { user } = useAuth()

  return (
    <AppLayout title="Dashboard">
      <section className="dashboard-card">
        <h2>Bienvenido</h2>
        <p>
          {user?.persona?.nombre_completo ?? user?.email}, has iniciado sesión
          correctamente.
        </p>
        {user?.empresa ? (
          <p className="dashboard-meta">Empresa: {user.empresa}</p>
        ) : null}
        {user?.roles.length ? (
          <p className="dashboard-meta">Roles: {user.roles.join(', ')}</p>
        ) : null}
      </section>
    </AppLayout>
  )
}
