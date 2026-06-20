import { NavLink } from 'react-router-dom'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { canAccessEmpresasModule, isAdministradorFon } from '@/features/auth/utils/roles'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', visible: () => true },
  { to: '/empresas', label: 'Empresas', visible: canAccessEmpresasModule },
  { to: '/impuestos', label: 'Impuestos', visible: isAdministradorFon },
  { to: '/usuarios', label: 'Usuarios', visible: isAdministradorFon },
] as const

export function Sidebar() {
  const { user } = useAuth()

  const visibleItems = navItems.filter((item) => item.visible(user))

  return (
    <aside className="sidebar">
      <div className="sidebar__brand">Arribo</div>
      <nav className="sidebar__nav">
        {visibleItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `sidebar__link${isActive ? ' sidebar__link--active' : ''}`
            }
          >
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  )
}
