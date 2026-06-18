import { NavLink } from 'react-router-dom'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { isAdministradorFon } from '@/features/auth/utils/roles'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', adminOnly: false },
  { to: '/empresas', label: 'Empresas', adminOnly: true },
  { to: '/impuestos', label: 'Impuestos', adminOnly: true },
  { to: '/usuarios', label: 'Usuarios', adminOnly: true },
] as const

export function Sidebar() {
  const { user } = useAuth()
  const isAdmin = isAdministradorFon(user)

  const visibleItems = navItems.filter((item) => !item.adminOnly || isAdmin)

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
