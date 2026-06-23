import { DropdownMenu } from '@/components/ui/DropdownMenu'
import type { Empresa } from '@/features/empresas/types/empresa.types'

interface EmpresaRowActionsProps {
  empresa: Empresa
  onEdit: (empresa: Empresa) => void
  onDelete: (empresa: Empresa) => void
  showFonActions?: boolean
  onActecos?: (empresa: Empresa) => void
  onTiposDocumento?: (empresa: Empresa) => void
  onRangosFolios?: (empresa: Empresa) => void
  onPersonasAutorizadas?: (empresa: Empresa) => void
  onCertificados?: (empresa: Empresa) => void
  onAuditoria?: (empresa: Empresa) => void
  onProductos?: (empresa: Empresa) => void
}

export function EmpresaRowActions({
  empresa,
  onEdit,
  onDelete,
  showFonActions = false,
  onActecos,
  onTiposDocumento,
  onRangosFolios,
  onPersonasAutorizadas,
  onCertificados,
  onAuditoria,
  onProductos,
}: EmpresaRowActionsProps) {
  return (
    <DropdownMenu
      ariaLabel={`Opciones de ${empresa.razon_social}`}
      items={[
        ...(showFonActions
          ? [
              {
                id: 'editar',
                label: 'Editar',
                onClick: () => onEdit(empresa),
              },
            ]
          : []),
        {
          id: 'actecos',
          label: 'Actividades económicas',
          disabled: !onActecos,
          onClick: onActecos ? () => onActecos(empresa) : undefined,
        },
        {
          id: 'tipos-documento',
          label: 'Tipos de documento',
          disabled: !onTiposDocumento,
          onClick: onTiposDocumento ? () => onTiposDocumento(empresa) : undefined,
        },
        {
          id: 'rangos-folios',
          label: 'Rangos de folios (CAF)',
          disabled: !onRangosFolios,
          onClick: onRangosFolios ? () => onRangosFolios(empresa) : undefined,
        },
        {
          id: 'personas',
          label: 'Personas autorizadas',
          disabled: !onPersonasAutorizadas,
          onClick: onPersonasAutorizadas
            ? () => onPersonasAutorizadas(empresa)
            : undefined,
        },
        {
          id: 'productos',
          label: 'Productos',
          disabled: !onProductos,
          onClick: onProductos ? () => onProductos(empresa) : undefined,
        },
        {
          id: 'auditoria',
          label: 'Auditoría',
          disabled: !onAuditoria,
          onClick: onAuditoria ? () => onAuditoria(empresa) : undefined,
        },
        ...(showFonActions && onCertificados
          ? [
              {
                id: 'certificados',
                label: 'Certificados',
                onClick: () => onCertificados(empresa),
              },
            ]
          : []),
        ...(showFonActions
          ? [
              {
                id: 'eliminar',
                label: 'Eliminar',
                variant: 'danger' as const,
                onClick: () => onDelete(empresa),
              },
            ]
          : []),
      ]}
    />
  )
}
