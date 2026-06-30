import type {
  EmisionReferencia,
  EmisionReferenciaRequest,
} from '@/features/emision/types/emision.types'
import { MAX_REFERENCIAS } from '@/features/emision/types/emision.types'
import type { TipoReferenciaDocumento } from '@/features/emision/types/tipoReferenciaDocumento.types'

const ISO_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/

export function validarReferencias(
  referencias: EmisionReferencia[],
  tiposPorCodigo: Map<string, TipoReferenciaDocumento>,
): string[] {
  const errores: string[] = []

  if (referencias.length > MAX_REFERENCIAS) {
    errores.push(`Máximo ${MAX_REFERENCIAS} referencias por documento.`)
    return errores
  }

  referencias.forEach((referencia, index) => {
    const n = index + 1
    const prefijo = `Referencia ${n}`

    const codigoTipo = referencia.tipo_documento_referencia.trim()
    if (!codigoTipo) {
      errores.push(`${prefijo}: seleccione el tipo de documento referenciado.`)
      return
    }

    const tipo = tiposPorCodigo.get(codigoTipo)
    if (!tipo) {
      errores.push(`${prefijo}: el tipo ${codigoTipo} no está disponible en el catálogo.`)
      return
    }

    const folio = referencia.folio_referencia.trim()
    if (tipo.requiere_folio && !folio) {
      errores.push(`${prefijo}: el folio es obligatorio.`)
    } else if (folio.length > 18) {
      errores.push(`${prefijo}: el folio no puede superar 18 caracteres.`)
    }

    const fecha = referencia.fecha_referencia.trim()
    if (tipo.requiere_fecha) {
      if (!fecha) {
        errores.push(`${prefijo}: la fecha es obligatoria.`)
      } else if (!ISO_DATE_PATTERN.test(fecha) || Number.isNaN(Date.parse(fecha))) {
        errores.push(`${prefijo}: la fecha debe tener formato AAAA-MM-DD.`)
      }
    }

    const razon = referencia.razon_referencia.trim()
    if (razon.length > 90) {
      errores.push(`${prefijo}: la razón no puede superar 90 caracteres.`)
    }

    const codigoRef = referencia.codigo_referencia.trim()
    if (codigoRef) {
      const codigo = Number(codigoRef)
      if (!Number.isInteger(codigo) || codigo < 1 || codigo > 4) {
        errores.push(`${prefijo}: el código de referencia debe estar entre 1 y 4.`)
      } else if (!tipo.permite_codigo_referencia) {
        errores.push(`${prefijo}: el código de referencia no aplica para el tipo ${codigoTipo}.`)
      }
    }
  })

  return errores
}

export function serializarReferenciasParaApi(
  referencias: EmisionReferencia[],
): EmisionReferenciaRequest[] {
  return referencias.map((referencia) => {
    const payload: EmisionReferenciaRequest = {
      tipo_documento_referencia: referencia.tipo_documento_referencia.trim(),
      folio_referencia: referencia.folio_referencia.trim(),
      fecha_referencia: referencia.fecha_referencia.trim(),
    }

    const razon = referencia.razon_referencia.trim()
    if (razon) {
      payload.razon_referencia = razon
    }

    const codigoRef = referencia.codigo_referencia.trim()
    if (codigoRef) {
      payload.codigo_referencia = Number(codigoRef)
    }

    if (referencia.documento_emitido_origen_id) {
      payload.documento_emitido_origen_id = referencia.documento_emitido_origen_id
    }

    return payload
  })
}
