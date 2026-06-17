import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { Empresa } from '@/features/empresas/types/empresa.types'

interface EmpresaRowActionsProps {
  empresa: Empresa
  onEdit: (empresa: Empresa) => void
  onDelete: (empresa: Empresa) => void
  onActecos?: (empresa: Empresa) => void
  onCertificados?: (empresa: Empresa) => void
}

export function EmpresaRowActions({
  empresa,
  onEdit,
  onDelete,
  onActecos,
  onCertificados,
}: EmpresaRowActionsProps) {
  return (
    <DropdownMenu
      ariaLabel={`Opciones de ${empresa.razon_social}`}
      items={[
        {
          id: 'editar',
          label: 'Editar',
          onClick: () => onEdit(empresa),
        },
        {
          id: 'actecos',
          label: 'Actividades económicas',
          disabled: !onActecos,
          onClick: onActecos ? () => onActecos(empresa) : undefined,
        },
        {
          id: 'certificados',
          label: 'Certificados',
          disabled: !onCertificados,
          onClick: onCertificados ? () => onCertificados(empresa) : undefined,
        },
        {
          id: 'eliminar',
          label: 'Eliminar',
          variant: 'danger',
          onClick: () => onDelete(empresa),
        },
      ]}
    />
  )
}
