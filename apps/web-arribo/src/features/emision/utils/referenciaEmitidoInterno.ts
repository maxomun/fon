import type { TipoReferenciaDocumento } from '@/features/emision/types/tipoReferenciaDocumento.types'

export function tipoReferenciaPermiteBuscarEmitidos(
  tiposPorCodigo: Map<string, TipoReferenciaDocumento>,
  codigoTipo: string,
) {
  return tiposPorCodigo.get(codigoTipo)?.categoria === 'DTE'
}

export function razonReferenciaPorDefecto(tipoDocumento: string) {
  switch (tipoDocumento) {
    case '52':
      return 'Facturación de guía de despacho'
    case '33':
    case '34':
      return 'Referencia a factura emitida'
    case '56':
    case '61':
      return 'Referencia a nota emitida'
    default:
      return ''
  }
}
