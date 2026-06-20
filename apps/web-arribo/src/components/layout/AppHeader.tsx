import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { displayUserName, formatRoles, hasAccesoGlobal } from '@/features/auth/utils/roles'

export function AppHeader() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    navigate('/login', { replace: true })
  }

  const displayName = displayUserName(user)
  const rolesLabel = formatRoles(user)

  return (
    <header className="app-header">
      <div className="app-header__content">
        <div className="app-header__user-info">
          {displayName ? <span className="app-header__name">{displayName}</span> : null}
          {user?.email ? <span className="app-header__email">{user.email}</span> : null}
          {rolesLabel ? <span className="app-header__roles">{rolesLabel}</span> : null}
          {hasAccesoGlobal(user) ? (
            <span className="app-header__empresa">Administrador FON</span>
          ) : null}
        </div>
        <Button variant="secondary" onClick={handleLogout}>
          Cerrar sesión
        </Button>
      </div>
    </header>
  )
}
