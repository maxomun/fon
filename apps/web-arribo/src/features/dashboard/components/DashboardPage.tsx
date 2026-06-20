import { AppLayout } from '@/components/layout/AppLayout'
import { useAuth } from '@/features/auth/hooks/useAuth'
import {
  displayUserName,
  formatRoles,
  getEmpresasAdministrables,
  hasAccesoGlobal,
} from '@/features/auth/utils/roles'

export function DashboardPage() {
  const { user } = useAuth()
  const empresasAdministrables = getEmpresasAdministrables(user)

  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p className="page-header__subtitle">
            {displayUserName(user) || user?.email}, has iniciado sesión correctamente.
          </p>
        </div>
      </div>

      <section className="panel-card">
        <h2>Bienvenido</h2>
        {hasAccesoGlobal(user) ? (
          <p className="dashboard-meta">Acceso global a la plataforma FON.</p>
        ) : null}
        {empresasAdministrables.length > 0 ? (
          <div className="dashboard-meta">
            <p>Empresas que puede administrar:</p>
            <ul>
              {empresasAdministrables.map((empresa) => (
                <li key={empresa.id}>{empresa.razon_social}</li>
              ))}
            </ul>
          </div>
        ) : null}
        {user?.roles.length ? (
          <p className="dashboard-meta">Roles: {formatRoles(user)}</p>
        ) : null}
      </section>
    </AppLayout>
  )
}
