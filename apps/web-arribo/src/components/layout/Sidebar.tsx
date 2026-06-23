import { NavLink } from 'react-router-dom'
import { Building2, LayoutDashboard, Receipt, ScrollText, Users } from 'lucide-react'
import { BrandLogo } from '@/components/brand/BrandLogo'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { canAccessEmpresasModule, isAdministradorFon } from '@/features/auth/utils/roles'
import { cn } from '@/lib/utils'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard, visible: () => true },
  { to: '/empresas', label: 'Empresas', icon: Building2, visible: canAccessEmpresasModule },
  { to: '/impuestos', label: 'Impuestos', icon: Receipt, visible: isAdministradorFon },
  { to: '/usuarios', label: 'Usuarios', icon: Users, visible: isAdministradorFon },
  { to: '/auditoria', label: 'Auditoría', icon: ScrollText, visible: isAdministradorFon },
] as const

export function Sidebar() {
  const { user } = useAuth()
  const visibleItems = navItems.filter((item) => item.visible(user))

  return (
    <aside className="bg-sidebar text-sidebar-foreground flex w-64 shrink-0 flex-col border-r border-sidebar-border">
      <div className="border-b border-sidebar-border px-5 py-5">
        <BrandLogo variant="sidebar" className="h-11 w-auto max-w-[220px] object-left" />
        <p className="text-sidebar-foreground/60 mt-2 text-xs font-medium tracking-wide">
          Portal Arribo
        </p>
      </div>

      <nav className="flex flex-1 flex-col gap-1 p-3">
        {visibleItems.map((item) => {
          const Icon = item.icon

          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-sidebar-accent text-sidebar-accent-foreground shadow-sm'
                    : 'text-sidebar-foreground/75 hover:bg-sidebar-accent/70 hover:text-sidebar-accent-foreground',
                )
              }
            >
              <Icon className="size-4 shrink-0" />
              {item.label}
            </NavLink>
          )
        })}
      </nav>
    </aside>
  )
}
