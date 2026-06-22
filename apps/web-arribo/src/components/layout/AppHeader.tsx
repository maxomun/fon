import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Loader2, LogOut } from 'lucide-react'
import { Button } from '@/components/ui'
import { Badge } from '@/components/ui/shadcn/badge'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { displayUserName, formatRoles, hasAccesoGlobal } from '@/features/auth/utils/roles'

export function AppHeader() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [isLoggingOut, setIsLoggingOut] = useState(false)

  async function handleLogout() {
    if (isLoggingOut) {
      return
    }

    setIsLoggingOut(true)

    try {
      await logout()
      navigate('/login', { replace: true })
    } finally {
      setIsLoggingOut(false)
    }
  }

  const displayName = displayUserName(user)
  const rolesLabel = formatRoles(user)

  return (
    <header className="bg-card/80 supports-[backdrop-filter]:bg-card/70 sticky top-0 z-10 border-b backdrop-blur">
      <div className="flex items-center justify-between gap-4 px-6 py-4 lg:px-8">
        <div className="min-w-0">
          {displayName ? (
            <p className="truncate text-sm font-semibold">{displayName}</p>
          ) : null}
          {user?.email ? (
            <p className="text-muted-foreground truncate text-sm">{user.email}</p>
          ) : null}
          <div className="mt-2 flex flex-wrap gap-2">
            {rolesLabel ? <Badge variant="secondary">{rolesLabel}</Badge> : null}
            {hasAccesoGlobal(user) ? <Badge>Administrador FON</Badge> : null}
          </div>
        </div>

        <Button
          variant="secondary"
          className="shrink-0"
          disabled={isLoggingOut}
          onClick={() => void handleLogout()}
        >
          {isLoggingOut ? (
            <>
              <Loader2 className="size-4 animate-spin" />
              Cerrando sesión…
            </>
          ) : (
            <>
              <LogOut className="size-4" />
              Cerrar sesión
            </>
          )}
        </Button>
      </div>
    </header>
  )
}
