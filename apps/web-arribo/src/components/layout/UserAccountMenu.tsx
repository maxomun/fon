import {
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
} from 'react'
import { useNavigate } from 'react-router-dom'
import { createPortal } from 'react-dom'
import { Info, Loader2, LogOut } from 'lucide-react'
import { AboutModal } from '@/components/layout/AboutModal'
import { UserAvatar } from '@/components/layout/UserAvatar'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { displayUserName } from '@/features/auth/utils/roles'

export function UserAccountMenu() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [isOpen, setIsOpen] = useState(false)
  const [isAboutOpen, setIsAboutOpen] = useState(false)
  const [isLoggingOut, setIsLoggingOut] = useState(false)
  const [panelStyle, setPanelStyle] = useState<CSSProperties>({})
  const triggerRef = useRef<HTMLButtonElement>(null)
  const panelRef = useRef<HTMLDivElement>(null)
  const menuId = useId()

  const displayName = displayUserName(user)
  const email = user?.email ?? ''

  useLayoutEffect(() => {
    if (!isOpen) {
      return
    }

    function updatePosition() {
      const trigger = triggerRef.current
      const panel = panelRef.current
      if (!trigger || !panel) {
        return
      }

      const rect = trigger.getBoundingClientRect()
      const panelHeight = panel.offsetHeight
      const gap = 8
      const spaceBelow = window.innerHeight - rect.bottom
      const openAbove = spaceBelow < panelHeight + gap && rect.top > panelHeight + gap

      setPanelStyle({
        position: 'fixed',
        top: openAbove ? rect.top - panelHeight - gap : rect.bottom + gap,
        left: rect.right,
        transform: 'translateX(-100%)',
        zIndex: 1000,
      })
    }

    updatePosition()

    window.addEventListener('resize', updatePosition)
    window.addEventListener('scroll', updatePosition, true)

    return () => {
      window.removeEventListener('resize', updatePosition)
      window.removeEventListener('scroll', updatePosition, true)
    }
  }, [isOpen])

  useEffect(() => {
    if (!isOpen) {
      return
    }

    function handleClickOutside(event: MouseEvent) {
      const target = event.target as Node

      if (triggerRef.current?.contains(target) || panelRef.current?.contains(target)) {
        return
      }

      setIsOpen(false)
    }

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    document.addEventListener('keydown', handleEscape)

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
      document.removeEventListener('keydown', handleEscape)
    }
  }, [isOpen])

  async function handleLogout() {
    if (isLoggingOut) {
      return
    }

    setIsOpen(false)
    setIsLoggingOut(true)

    try {
      await logout()
      navigate('/login', { replace: true })
    } finally {
      setIsLoggingOut(false)
    }
  }

  function openAbout() {
    setIsOpen(false)
    setIsAboutOpen(true)
  }

  const panel = isOpen ? (
    <div
      id={menuId}
      ref={panelRef}
      className="user-account-menu__panel"
      role="menu"
      aria-label="Cuenta de usuario"
      style={panelStyle}
    >
      <div className="user-account-menu__profile">
        <UserAvatar displayName={displayName} email={email} size="lg" />
        <div className="user-account-menu__profile-text">
          {displayName ? (
            <p className="user-account-menu__name">{displayName}</p>
          ) : null}
          {email ? <p className="user-account-menu__email">{email}</p> : null}
        </div>
      </div>

      <div className="user-account-menu__separator" role="separator" />

      <button
        type="button"
        role="menuitem"
        className="user-account-menu__item"
        onClick={openAbout}
      >
        <Info className="user-account-menu__item-icon" aria-hidden="true" />
        Acerca de FacturaOn
      </button>

      <div className="user-account-menu__separator" role="separator" />

      <button
        type="button"
        role="menuitem"
        className="user-account-menu__item"
        disabled={isLoggingOut}
        onClick={() => void handleLogout()}
      >
        {isLoggingOut ? (
          <Loader2 className="user-account-menu__item-icon animate-spin" aria-hidden="true" />
        ) : (
          <LogOut className="user-account-menu__item-icon" aria-hidden="true" />
        )}
        {isLoggingOut ? 'Cerrando sesión…' : 'Cerrar sesión'}
      </button>
    </div>
  ) : null

  return (
    <>
      <div className="user-account-menu">
        <button
          ref={triggerRef}
          type="button"
          className="user-account-menu__trigger"
          aria-label="Cuenta de usuario"
          aria-haspopup="menu"
          aria-expanded={isOpen}
          aria-controls={menuId}
          onClick={() => setIsOpen((open) => !open)}
        >
          <UserAvatar displayName={displayName} email={email} size="sm" />
        </button>

        {panel ? createPortal(panel, document.body) : null}
      </div>

      <AboutModal isOpen={isAboutOpen} onClose={() => setIsAboutOpen(false)} />
    </>
  )
}
