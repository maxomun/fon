import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { Producto } from '@/features/productos/types/producto.types'

interface ProductoRowActionsProps {
  producto: Producto
  canEdit: boolean
  onEdit: (producto: Producto) => void
  onDelete: (producto: Producto) => void
}

export function ProductoRowActions({
  producto,
  canEdit,
  onEdit,
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
