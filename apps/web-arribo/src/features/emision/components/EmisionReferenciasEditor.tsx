import { Fragment, useMemo, useState } from 'react'
import { Button } from '@/components/ui'
import { EmisionReferenciaBuscarPanel } from '@/features/emision/components/EmisionReferenciaBuscarPanel'
import type { EmisionReferencia } from '@/features/emision/types/emision.types'
import {
  EMISION_CODIGO_REFERENCIA_OPCIONES,
  MAX_REFERENCIAS,
} from '@/features/emision/types/emision.types'
import type { TipoReferenciaDocumento } from '@/features/emision/types/tipoReferenciaDocumento.types'
import type { DocumentoParaReferencia } from '@/features/documentos/types/documentoEmitido.types'
import {
  razonReferenciaPorDefecto,
  tipoReferenciaPermiteBuscarEmitidos,
} from '@/features/emision/utils/referenciaEmitidoInterno'

interface EmisionReferenciasEditorProps {
  empresaId: number
  rutReceptor?: string
  referencias: EmisionReferencia[]
  tiposReferencia: TipoReferenciaDocumento[]
  disabled?: boolean
  onAdd: () => void
  onRemove: (key: string) => void
  onChange: (key: string, patch: Partial<EmisionReferencia>) => void
}

export function EmisionReferenciasEditor({
  empresaId,
  rutReceptor,
  referencias,
  tiposReferencia,
  disabled,
  onAdd,
  onRemove,
  onChange,
}: EmisionReferenciasEditorProps) {
  const [buscarKey, setBuscarKey] = useState<string | null>(null)

  const tiposPorCodigo = useMemo(
    () => new Map(tiposReferencia.map((tipo) => [tipo.codigo_sii, tipo])),
    [tiposReferencia],
  )

  function aplicarDocumentoEmitido(referenciaKey: string, documento: DocumentoParaReferencia) {
    const razonActual = referencias.find((item) => item.key === referenciaKey)?.razon_referencia

    onChange(referenciaKey, {
      tipo_documento_referencia: documento.tipo_documento,
      folio_referencia: String(documento.folio),
      fecha_referencia: documento.fecha_emision?.slice(0, 10) || '',
      documento_emitido_origen_id: documento.id,
      razon_referencia:
        razonActual?.trim() || razonReferenciaPorDefecto(documento.tipo_documento),
    })
    setBuscarKey(null)
  }

  return (
    <div className="emision-wizard__referencias">
      <div className="emision-wizard__lineas-header">
        <div>
          <h3>Referencias</h3>
          <p className="emision-wizard__hint emision-wizard__hint--inline">
            Opcional. Relaciona la factura con guías, órdenes de compra u otros documentos (
            <code>Referencia</code> en el XML). Para tipos DTE emitidos en FacturaOn puede buscar
            por folio o receptor.
          </p>
        </div>
        <Button
          type="button"
          variant="secondary"
          disabled={disabled || referencias.length >= MAX_REFERENCIAS}
          onClick={onAdd}
        >
          Agregar referencia
        </Button>
      </div>

      {referencias.length === 0 ? (
        <p className="emision-wizard__hint">
          Sin referencias. Use el botón para vincular guías de despacho (52), órdenes de compra
          (801) u otros documentos del catálogo SII.
        </p>
      ) : (
        <div className="emision-wizard__lineas-scroll">
          <table className="emision-wizard__lineas-table emision-wizard__referencias-table">
            <thead>
              <tr>
                <th className="emision-wizard__col-num" scope="col">
                  #
                </th>
                <th scope="col">Tipo documento</th>
                <th className="emision-wizard__col-folio-ref" scope="col">
                  Folio
                </th>
                <th className="emision-wizard__col-fecha-ref" scope="col">
                  Fecha
                </th>
                <th scope="col">Razón</th>
                <th className="emision-wizard__col-cod-ref" scope="col">
                  Cod. ref.
                </th>
                <th className="emision-wizard__col-actions" scope="col" aria-label="Acciones" />
              </tr>
            </thead>
            <tbody>
              {referencias.map((referencia, index) => {
                const tipoSeleccionado = tiposPorCodigo.get(referencia.tipo_documento_referencia)
                const muestraCodRef = tipoSeleccionado?.permite_codigo_referencia ?? false
                const permiteBuscar = tipoReferenciaPermiteBuscarEmitidos(
                  tiposPorCodigo,
                  referencia.tipo_documento_referencia,
                )

                return (
                  <Fragment key={referencia.key}>
                    <tr>
                      <td className="emision-wizard__col-num">{index + 1}</td>
                      <td>
                        <select
                          className="emision-wizard__linea-input"
                          value={referencia.tipo_documento_referencia}
                          disabled={disabled}
                          aria-label={`Tipo documento referencia ${index + 1}`}
                          onChange={(event) => {
                            const codigo = event.target.value
                            const tipo = tiposPorCodigo.get(codigo)
                            const patch: Partial<EmisionReferencia> = {
                              tipo_documento_referencia: codigo,
                              documento_emitido_origen_id: null,
                            }

                            if (tipo && !tipo.permite_codigo_referencia) {
                              patch.codigo_referencia = ''
                            }

                            if (buscarKey === referencia.key) {
                              setBuscarKey(null)
                            }

                            onChange(referencia.key, patch)
                          }}
                        >
                          <option value="">Seleccione…</option>
                          {tiposReferencia.map((tipo) => (
                            <option key={tipo.id} value={tipo.codigo_sii}>
                              {tipo.codigo_sii} — {tipo.nombre}
                            </option>
                          ))}
                        </select>
                        {permiteBuscar ? (
                          <button
                            type="button"
                            className="emision-referencia-buscar__toggle"
                            disabled={disabled || !referencia.tipo_documento_referencia}
                            onClick={() =>
                              setBuscarKey((current) =>
                                current === referencia.key ? null : referencia.key,
                              )
                            }
                          >
                            {buscarKey === referencia.key ? 'Ocultar búsqueda' : 'Buscar emitido'}
                          </button>
                        ) : null}
                        {referencia.documento_emitido_origen_id ? (
                          <span className="emision-referencia-buscar__vinculo">
                            Vinculado a DTE #{referencia.documento_emitido_origen_id}
                          </span>
                        ) : null}
                      </td>
                      <td className="emision-wizard__col-folio-ref">
                        <input
                          className="emision-wizard__linea-input"
                          type="text"
                          maxLength={18}
                          placeholder="4589"
                          value={referencia.folio_referencia}
                          disabled={disabled}
                          aria-label={`Folio referencia ${index + 1}`}
                          onChange={(event) =>
                            onChange(referencia.key, {
                              folio_referencia: event.target.value,
                              documento_emitido_origen_id: null,
                            })
                          }
                        />
                      </td>
                      <td className="emision-wizard__col-fecha-ref">
                        <input
                          className="emision-wizard__linea-input emision-wizard__linea-input--num"
                          type="date"
                          value={referencia.fecha_referencia}
                          disabled={disabled}
                          aria-label={`Fecha referencia ${index + 1}`}
                          onChange={(event) =>
                            onChange(referencia.key, {
                              fecha_referencia: event.target.value,
                              documento_emitido_origen_id: null,
                            })
                          }
                        />
                      </td>
                      <td>
                        <input
                          className="emision-wizard__linea-input"
                          type="text"
                          maxLength={90}
                          placeholder="Facturación de guía de despacho"
                          value={referencia.razon_referencia}
                          disabled={disabled}
                          aria-label={`Razón referencia ${index + 1}`}
                          onChange={(event) =>
                            onChange(referencia.key, { razon_referencia: event.target.value })
                          }
                        />
                      </td>
                      <td className="emision-wizard__col-cod-ref">
                        {muestraCodRef ? (
                          <select
                            className="emision-wizard__linea-input emision-wizard__linea-input--num"
                            value={referencia.codigo_referencia}
                            disabled={disabled}
                            aria-label={`Código referencia ${index + 1}`}
                            onChange={(event) =>
                              onChange(referencia.key, { codigo_referencia: event.target.value })
                            }
                          >
                            <option value="">—</option>
                            {EMISION_CODIGO_REFERENCIA_OPCIONES.map((opcion) => (
                              <option key={opcion.value} value={opcion.value}>
                                {opcion.label}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <span className="emision-wizard__linea-readonly">—</span>
                        )}
                      </td>
                      <td className="emision-wizard__col-actions">
                        <button
                          type="button"
                          className="emision-wizard__linea-remove"
                          disabled={disabled}
                          aria-label={`Quitar referencia ${index + 1}`}
                          onClick={() => {
                            if (buscarKey === referencia.key) {
                              setBuscarKey(null)
                            }
                            onRemove(referencia.key)
                          }}
                        >
                          Quitar
                        </button>
                      </td>
                    </tr>
                    {buscarKey === referencia.key && permiteBuscar ? (
                      <tr key={`${referencia.key}-buscar`} className="emision-referencia-buscar__row">
                        <td colSpan={7}>
                          <EmisionReferenciaBuscarPanel
                            empresaId={empresaId}
                            tipoDocumentoReferencia={referencia.tipo_documento_referencia}
                            rutReceptor={rutReceptor}
                            disabled={disabled}
                            onSelect={(documento) =>
                              aplicarDocumentoEmitido(referencia.key, documento)
                            }
                          />
                        </td>
                      </tr>
                    ) : null}
                  </Fragment>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
