import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { Producto } from '@/features/productos/types/producto.types'

interface ProductoRowActionsProps {
  producto: Producto
  canEdit: boolean
  isDuplicating?: boolean
  onEdit: (producto: Producto) => void
  onDuplicate: (producto: Producto) => void
  onDelete: (producto: Producto) => void
}

export function ProductoRowActions({
  producto,
  canEdit,
  isDuplicating = false,
  onEdit,
  onDuplicate,
  onDelete,
}: ProductoRowActionsProps) {
  if (!canEdit) {
    return null
  }

  return (
    <DropdownMenu
      ariaLabel={`Opciones de ${producto.nombre}`}
      items={[
        {
          id: 'editar',
          label: 'Editar',
          onClick: () => onEdit(producto),
        },
        {
          id: 'duplicar',
          label: isDuplicating ? 'Duplicando…' : 'Duplicar',
          disabled: isDuplicating,
          onClick: isDuplicating ? undefined : () => onDuplicate(producto),
        },
        {
          id: 'eliminar',
          label: 'Eliminar',
          variant: 'danger',
          disabled: producto.tiene_ventas,
          onClick: producto.tiene_ventas ? undefined : () => onDelete(producto),
        },
      ]}
    />
  )
}
