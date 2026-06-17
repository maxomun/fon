import {
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from 'react'
import { createPortal } from 'react-dom'

export interface DropdownMenuItem {
  id: string
  label: string
  onClick?: () => void
  disabled?: boolean
  variant?: 'default' | 'danger'
}

interface DropdownMenuProps {
  items: DropdownMenuItem[]
  ariaLabel?: string
  trigger?: ReactNode
}

export function DropdownMenu({
  items,
  ariaLabel = 'Más opciones',
  trigger,
}: DropdownMenuProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [panelStyle, setPanelStyle] = useState<CSSProperties>({})
  const triggerRef = useRef<HTMLButtonElement>(null)
  const panelRef = useRef<HTMLDivElement>(null)
  const menuId = useId()

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
      const gap = 4
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
  }, [isOpen, items])

  useEffect(() => {
    if (!isOpen) {
      return
    }

    function handleClickOutside(event: MouseEvent) {
      const target = event.target as Node

      if (
        triggerRef.current?.contains(target) ||
        panelRef.current?.contains(target)
      ) {
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

  function handleItemClick(item: DropdownMenuItem) {
    if (item.disabled || !item.onClick) {
      return
    }

    item.onClick()
    setIsOpen(false)
  }

  const defaultItems = items.filter((item) => item.variant !== 'danger')
  const dangerItems = items.filter((item) => item.variant === 'danger')

  const panel = isOpen ? (
    <div
      id={menuId}
      ref={panelRef}
      className="dropdown-menu__panel"
      role="menu"
      style={panelStyle}
    >
      {defaultItems.map((item) => (
        <button
          key={item.id}
          type="button"
          role="menuitem"
          className="dropdown-menu__item"
          disabled={item.disabled}
          onClick={() => handleItemClick(item)}
        >
          {item.label}
        </button>
      ))}

      {defaultItems.length > 0 && dangerItems.length > 0 ? (
        <div className="dropdown-menu__separator" role="separator" />
      ) : null}

      {dangerItems.map((item) => (
        <button
          key={item.id}
          type="button"
          role="menuitem"
          className="dropdown-menu__item dropdown-menu__item--danger"
          disabled={item.disabled}
          onClick={() => handleItemClick(item)}
        >
          {item.label}
        </button>
      ))}
    </div>
  ) : null

  return (
    <div className="dropdown-menu">
      <button
        ref={triggerRef}
        type="button"
        className="dropdown-menu__trigger"
        aria-label={ariaLabel}
        aria-haspopup="menu"
        aria-expanded={isOpen}
        aria-controls={menuId}
        onClick={() => setIsOpen((open) => !open)}
      >
        {trigger ?? (
          <span className="dropdown-menu__dots" aria-hidden="true">
            ⋮
          </span>
        )}
      </button>

      {panel ? createPortal(panel, document.body) : null}
    </div>
  )
}
