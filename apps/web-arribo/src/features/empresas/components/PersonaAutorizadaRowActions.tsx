import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { PersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'
import { puedeEliminarPersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'

interface PersonaAutorizadaRowActionsProps {
  persona: PersonaAutorizada
  variant: 'search' | 'assigned'
  isFonAdmin?: boolean
  isAssigning?: boolean
  isUpdatingAdmin?: boolean
  onEdit: (persona: PersonaAutorizada) => void
  onAssign?: (persona: PersonaAutorizada) => void
  onDelete?: (persona: PersonaAutorizada) => void
  onRemove?: (persona: PersonaAutorizada) => void
  onToggleAdmin?: (persona: PersonaAutorizada) => void
}

export function PersonaAutorizadaRowActions({
  persona,
  variant,
  isFonAdmin = false,
  isAssigning = false,
  isUpdatingAdmin = false,
  onEdit,
  onAssign,
  onDelete,
  onRemove,
  onToggleAdmin,
}: PersonaAutorizadaRowActionsProps) {
  const adminLabel = persona.es_administrador_empresa ? 'Quitar admin' : 'Hacer admin'

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
