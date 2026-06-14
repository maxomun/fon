import type { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'

interface AppLayoutProps {
  title: string
  children: ReactNode
}

export function AppLayout({ title, children }: AppLayoutProps) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    navigate('/login', { replace: true })
  }

  const displayName =
    user?.persona?.nombre_completo ?? user?.email ?? user?.username

  return (
    <div className="app-layout">
      <header className="app-header">
        <div className="app-header__content">
          <h1>{title}</h1>
          <div className="app-header__actions">
            {displayName ? (
              <span className="app-header__user">{displayName}</span>
            ) : null}
            <Button variant="secondary" onClick={handleLogout}>
              Cerrar sesión
            </Button>
          </div>
        </div>
      </header>
      <main className="app-main">{children}</main>
    </div>
  )
}
