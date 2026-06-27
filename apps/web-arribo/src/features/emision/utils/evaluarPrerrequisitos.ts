import type {
  PrerrequisitoItem,
  PrerrequisitosInput,
  PrerrequisitosResultado,
} from '@/features/emision/types/prerrequisitos.types'

export const FOLIOS_BAJOS_UMBRAL = 5
export const CERTIFICADO_DIAS_AVISO = 30

export const EMISION_VER_REQUISITOS_QUERY = 'requisitos'

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

function diasHastaFecha(value: string | null) {
  if (!value) {
    return null
  }

  const fecha = new Date(value)
  if (Number.isNaN(fecha.getTime())) {
    return null
  }

  const hoy = new Date()
  hoy.setHours(0, 0, 0, 0)
  fecha.setHours(0, 0, 0, 0)

  return Math.ceil((fecha.getTime() - hoy.getTime()) / (1000 * 60 * 60 * 24))
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

export function debeRedirigirAlWizard(resultado: PrerrequisitosResultado) {
  return resultado.listoParaEmitir && resultado.advertencias === 0
}

export function rutaEmitirRequisitos(empresaId: number) {
  return `/empresas/${empresaId}/emitir?ver=${EMISION_VER_REQUISITOS_QUERY}`
}

export function evaluarPrerrequisitos(input: PrerrequisitosInput): PrerrequisitosResultado {
  const { empresaId, empresa, productosActivosCount, tiposHabilitados, personas } = input

  const foliosDisponibles = tiposHabilitados.reduce(
    (total, tipo) => total + tipo.folios_disponibles,
    0,
  )
  const foliosBajos =
    foliosDisponibles > 0 && foliosDisponibles < FOLIOS_BAJOS_UMBRAL
  const diasCertificado = diasHastaFecha(empresa.fecha_caducacion_certificado)
  const certificadoPorVencer =
    empresa.tiene_certificado_vigente &&
    diasCertificado !== null &&
    diasCertificado <= CERTIFICADO_DIAS_AVISO
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
      estado:
        foliosDisponibles === 0 ? 'pendiente' : foliosBajos ? 'advertencia' : 'ok',
      mensaje:
        foliosDisponibles === 0
          ? tiposHabilitados.length === 0
            ? 'Primero habilite un tipo de documento y luego cargue un archivo CAF.'
            : 'Debe cargar un rango CAF con folios disponibles para el tipo habilitado.'
          : foliosBajos
            ? `Quedan ${foliosDisponibles} folio${foliosDisponibles === 1 ? '' : 's'} disponible${foliosDisponibles === 1 ? '' : 's'}. Considere cargar un nuevo CAF antes de quedarse sin folios.`
            : `${foliosDisponibles} folio${foliosDisponibles === 1 ? '' : 's'} disponible${foliosDisponibles === 1 ? '' : 's'} para timbrar.`,
      linkTo: `/empresas/${empresaId}/rangos-folios`,
      linkLabel: 'Ir a rangos de folios',
    },
    {
      id: 'certificado',
      titulo: 'Certificado digital vigente',
      estado: !empresa.tiene_certificado_vigente
        ? 'pendiente'
        : certificadoPorVencer
          ? 'advertencia'
          : 'ok',
      mensaje: !empresa.tiene_certificado_vigente
        ? 'La empresa no tiene un certificado digital vigente para firmar documentos.'
        : certificadoPorVencer
          ? `El certificado vence${formatFechaCertificado(empresa.fecha_caducacion_certificado) ? ` el ${formatFechaCertificado(empresa.fecha_caducacion_certificado)}` : ' pronto'} (${diasCertificado === 0 ? 'hoy' : `en ${diasCertificado} día${diasCertificado === 1 ? '' : 's'}`}). Renueve a tiempo para evitar interrupciones.`
          : `Certificado vigente${formatFechaCertificado(empresa.fecha_caducacion_certificado) ? ` hasta el ${formatFechaCertificado(empresa.fecha_caducacion_certificado)}` : ''}.`,
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
  const advertencias = items.filter((item) => item.estado === 'advertencia').length

  return {
    items,
    listoParaEmitir: pendientes === 0,
    pendientes,
    advertencias,
  }
}
