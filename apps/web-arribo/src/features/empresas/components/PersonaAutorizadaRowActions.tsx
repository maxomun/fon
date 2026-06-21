import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { PersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'
import {
  puedeEliminarPersonaAutorizada,
  puedeReenviarOnboarding,
} from '@/features/empresas/types/personaAutorizada.types'

interface PersonaAutorizadaRowActionsProps {
  persona: PersonaAutorizada
  variant: 'search' | 'assigned'
  isFonAdmin?: boolean
  isAssigning?: boolean
  isUpdatingAdmin?: boolean
  isResendingOnboarding?: boolean
  onEdit: (persona: PersonaAutorizada) => void
  onAssign?: (persona: PersonaAutorizada) => void
  onDelete?: (persona: PersonaAutorizada) => void
  onRemove?: (persona: PersonaAutorizada) => void
  onToggleAdmin?: (persona: PersonaAutorizada) => void
  onReenviarOnboarding?: (persona: PersonaAutorizada) => void
}

export function PersonaAutorizadaRowActions({
  persona,
  variant,
  isFonAdmin = false,
  isAssigning = false,
  isUpdatingAdmin = false,
  isResendingOnboarding = false,
  onEdit,
  onAssign,
  onDelete,
  onRemove,
  onToggleAdmin,
  onReenviarOnboarding,
}: PersonaAutorizadaRowActionsProps) {
  const adminLabel = persona.es_administrador_empresa ? 'Quitar admin' : 'Hacer admin'

  const reenviarItem =
    isFonAdmin && puedeReenviarOnboarding(persona)
      ? [
          {
            id: 'reenviar-onboarding',
            label: isResendingOnboarding ? 'Enviando…' : 'Reenviar enrolamiento',
            disabled: isResendingOnboarding,
            onClick: onReenviarOnboarding
              ? () => onReenviarOnboarding(persona)
              : undefined,
          },
        ]
      : []

  const searchItems = [
    {
      id: 'asignar',
      label: isAssigning ? 'Asignando…' : 'Asignar',
      disabled: isAssigning,
      onClick: onAssign ? () => onAssign(persona) : undefined,
    },
    {
      id: 'editar',
      label: 'Editar',
      onClick: () => onEdit(persona),
    },
    ...reenviarItem,
    ...(isFonAdmin
      ? [
          {
            id: 'eliminar',
            label: 'Eliminar',
            variant: 'danger' as const,
            disabled: !puedeEliminarPersonaAutorizada(persona),
            onClick: onDelete ? () => onDelete(persona) : undefined,
          },
        ]
      : []),
  ]

  const assignedItems = [
    {
      id: 'admin',
      label: isUpdatingAdmin ? 'Guardando…' : adminLabel,
      disabled: isUpdatingAdmin,
      onClick: onToggleAdmin ? () => onToggleAdmin(persona) : undefined,
    },
    {
      id: 'editar',
      label: 'Editar',
      onClick: () => onEdit(persona),
    },
    ...reenviarItem,
    {
      id: 'quitar',
      label: 'Quitar de esta empresa',
      variant: 'danger' as const,
      onClick: onRemove ? () => onRemove(persona) : undefined,
    },
  ]

  return (
    <DropdownMenu
      ariaLabel={`Opciones de ${persona.nombre_completo}`}
      items={variant === 'search' ? searchItems : assignedItems}
    />
  )
}
