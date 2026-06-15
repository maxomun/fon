import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { formatRoles } from '@/features/auth/utils/roles'

export function AppHeader() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    navigate('/login', { replace: true })
  }

  const displayName =
    user?.persona?.nombre_completo ?? user?.username ?? user?.email
  const rolesLabel = formatRoles(user)

  return (
    <header className="app-header">
      <div className="app-header__content">
        <div className="app-header__user-info">
          {displayName ? (
            <span className="app-header__name">{displayName}</span>
          ) : null}
          {user?.email ? (
            <span className="app-header__email">{user.email}</span>
          ) : null}
          {rolesLabel ? (
            <span className="app-header__roles">{rolesLabel}</span>
          ) : null}
          {user?.empresa ? (
            <span className="app-header__empresa">{user.empresa}</span>
          ) : null}
        </div>
        <Button variant="secondary" onClick={handleLogout}>
          Cerrar sesión
        </Button>
      </div>
    </header>
  )
}
