import type {
  PrerrequisitoItem,
  PrerrequisitosInput,
  PrerrequisitosResultado,
} from '@/features/emision/types/prerrequisitos.types'

function formatFechaCertificado(value: string | null) {
  if (!value) {
    return null
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleDateString('es-CL')
}

function tiposHabilitadosLabel(tipos: PrerrequisitosInput['tiposHabilitados']) {
  if (tipos.length === 0) {
    return ''
  }

  const codigos = tipos
    .map((tipo) => tipo.tipo_documento.codigo)
    .filter(Boolean)
    .join(', ')

  return codigos ? ` (${codigos})` : ''
}

export function evaluarPrerrequisitos(input: PrerrequisitosInput): PrerrequisitosResultado {
  const { empresaId, empresa, productosActivosCount, tiposHabilitados, personas } = input

  const foliosDisponibles = tiposHabilitados.reduce(
    (total, tipo) => total + tipo.folios_disponibles,
    0,
  )
  const personasConCertificado = personas.filter((persona) => persona.tiene_certificado_vigente)

  const items: PrerrequisitoItem[] = [
    {
      id: 'productos',
      titulo: 'Productos activos',
      estado: productosActivosCount > 0 ? 'ok' : 'pendiente',
      mensaje:
        productosActivosCount > 0
          ? `${productosActivosCount} producto${productosActivosCount === 1 ? '' : 's'} activo${productosActivosCount === 1 ? '' : 's'} en el catálogo.`
          : 'Debe registrar al menos un producto activo para facturar.',
      linkTo: `/empresas/${empresaId}/productos`,
      linkLabel: 'Ir a productos',
    },
    {
      id: 'tipos_documento',
      titulo: 'Tipos de documento habilitados',
      estado: tiposHabilitados.length > 0 ? 'ok' : 'pendiente',
      mensaje:
        tiposHabilitados.length > 0
          ? `${tiposHabilitados.length} tipo${tiposHabilitados.length === 1 ? '' : 's'} habilitado${tiposHabilitados.length === 1 ? '' : 's'}${tiposHabilitadosLabel(tiposHabilitados)}.`
          : 'Debe habilitar al menos un tipo de documento (por ejemplo, factura electrónica 33).',
      linkTo: `/empresas/${empresaId}/tipos-documentos`,
      linkLabel: 'Ir a tipos de documento',
    },
    {
      id: 'folios',
      titulo: 'Folios CAF disponibles',
      estado: foliosDisponibles > 0 ? 'ok' : 'pendiente',
      mensaje:
        foliosDisponibles > 0
          ? `${foliosDisponibles} folio${foliosDisponibles === 1 ? '' : 's'} disponible${foliosDisponibles === 1 ? '' : 's'} para timbrar.`
          : tiposHabilitados.length === 0
            ? 'Primero habilite un tipo de documento y luego cargue un archivo CAF.'
            : 'Debe cargar un rango CAF con folios disponibles para el tipo habilitado.',
      linkTo: `/empresas/${empresaId}/rangos-folios`,
      linkLabel: 'Ir a rangos de folios',
    },
    {
      id: 'certificado',
      titulo: 'Certificado digital vigente',
      estado: empresa.tiene_certificado_vigente ? 'ok' : 'pendiente',
      mensaje: empresa.tiene_certificado_vigente
        ? `Certificado vigente${formatFechaCertificado(empresa.fecha_caducacion_certificado) ? ` hasta el ${formatFechaCertificado(empresa.fecha_caducacion_certificado)}` : ''}.`
        : 'La empresa no tiene un certificado digital vigente para firmar documentos.',
      linkTo: `/empresas/${empresaId}/certificados`,
      linkLabel: 'Ir a certificados',
      ayudaSinLink:
        'Solicite a FacturaOn la carga del certificado digital de la empresa.',
    },
    {
      id: 'persona_certificado',
      titulo: 'Persona autorizada con certificado',
      estado: personasConCertificado.length > 0 ? 'ok' : 'pendiente',
      mensaje:
        personasConCertificado.length > 0
          ? `${personasConCertificado.length} persona${personasConCertificado.length === 1 ? '' : 's'} con certificado vigente para firmar.`
          : 'Debe asignar una persona autorizada y asociarle un certificado digital.',
      linkTo: `/empresas/${empresaId}/personas-autorizadas`,
      linkLabel: 'Ir a personas autorizadas',
      ayudaSinLink:
        'Contacte a FacturaOn para cargar el certificado de una persona autorizada.',
    },
  ]

  const pendientes = items.filter((item) => item.estado === 'pendiente').length

  return {
    items,
    listoParaEmitir: pendientes === 0,
    pendientes,
  }
}
