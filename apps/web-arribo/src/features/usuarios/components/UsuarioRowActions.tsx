import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { Usuario } from '@/features/usuarios/types/usuario.types'
import { esUsuarioPlataformaEditable } from '@/features/usuarios/types/usuario.types'

interface UsuarioRowActionsProps {
  usuario: Usuario
  isCurrentUser: boolean
  isUpdatingEstado?: boolean
  isReenviandoAcceso?: boolean
  onEdit: (usuario: Usuario) => void
  onVerDetalle: (usuario: Usuario) => void
  onToggleEstado: (usuario: Usuario) => void
  onReenviarAcceso: (usuario: Usuario) => void
}

export function UsuarioRowActions({
  usuario,
  isCurrentUser,
  isUpdatingEstado = false,
  isReenviandoAcceso = false,
  onEdit,
  onVerDetalle,
  onToggleEstado,
  onReenviarAcceso,
}: UsuarioRowActionsProps) {
  if (!esUsuarioPlataformaEditable(usuario)) {
    return (
      <DropdownMenu
        ariaLabel={`Opciones de ${usuario.nombre_completo ?? usuario.email}`}
        items={[
          {
            id: 'ver',
            label: 'Ver detalle',
            onClick: () => onVerDetalle(usuario),
          },
        ]}
      />
    )
  }

  const estadoLabel = usuario.activo ? 'Desactivar' : 'Activar'

  return (
    <DropdownMenu
      ariaLabel={`Opciones de ${usuario.nombre_completo ?? usuario.email}`}
      items={[
        {
          id: 'editar',
          label: 'Editar',
          onClick: () => onEdit(usuario),
        },
        {
          id: 'estado',
          label: isUpdatingEstado ? 'Guardando…' : estadoLabel,
          disabled: isUpdatingEstado || (isCurrentUser && usuario.activo),
          onClick: () => onToggleEstado(usuario),
        },
        {
          id: 'reenviar',
          label: isReenviandoAcceso ? 'Enviando…' : 'Reenviar acceso',
          disabled: isReenviandoAcceso || !usuario.activo,
          onClick: () => onReenviarAcceso(usuario),
        },
      ]}
    />
  )
}
