import { useEffect, useState } from 'react'
import { Button } from '@/components/ui'
import type { DocumentoParaReferencia } from '@/features/documentos/types/documentoEmitido.types'
import { documentosService } from '@/features/documentos/services/documentosService'
import {
  formatDocumentoFechaSolo,
  formatDocumentoMonto,
} from '@/features/documentos/types/documentoEmitido.types'
import { ApiError } from '@/services/apiClient'

const BUSCAR_DEBOUNCE_MS = 300

interface EmisionReferenciaBuscarPanelProps {
  empresaId: number
  tipoDocumentoReferencia: string
  rutReceptor?: string
  disabled?: boolean
  onSelect: (documento: DocumentoParaReferencia) => void
}

export function EmisionReferenciaBuscarPanel({
  empresaId,
  tipoDocumentoReferencia,
  rutReceptor,
  disabled,
  onSelect,
}: EmisionReferenciaBuscarPanelProps) {
  const [query, setQuery] = useState('')
  const [resultados, setResultados] = useState<DocumentoParaReferencia[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!tipoDocumentoReferencia) {
      setResultados([])
      setError(null)
      return
    }

    let cancelado = false
    const timer = window.setTimeout(() => {
      void (async () => {
        setIsSearching(true)
        setError(null)

        try {
          const response = await documentosService.buscarParaReferencia(
            empresaId,
            tipoDocumentoReferencia,
            query,
            { rutReceptor, limit: 20 },
          )

          if (cancelado) {
            return
          }

          setResultados(response.data ?? [])
        } catch (err) {
          if (cancelado) {
            return
          }

          setResultados([])
          setError(err instanceof ApiError ? err.message : 'No se pudo buscar documentos emitidos.')
        } finally {
          if (!cancelado) {
            setIsSearching(false)
          }
        }
      })()
    }, BUSCAR_DEBOUNCE_MS)

    return () => {
      cancelado = true
      window.clearTimeout(timer)
    }
  }, [empresaId, query, rutReceptor, tipoDocumentoReferencia])

  return (
    <div className="emision-referencia-buscar">
      <div className="emision-referencia-buscar__header">
        <input
          className="emision-wizard__linea-input"
          type="search"
          placeholder="Buscar por folio, RUT o razón social del receptor"
          value={query}
          disabled={disabled}
          aria-label="Buscar DTE emitido para referenciar"
          onChange={(event) => setQuery(event.target.value)}
        />
        {rutReceptor?.trim() ? (
          <p className="emision-wizard__hint emision-referencia-buscar__hint">
            Priorizando documentos del receptor {rutReceptor.trim()}.
          </p>
        ) : null}
      </div>

      {error ? <p className="emision-referencia-buscar__error">{error}</p> : null}

      {isSearching ? (
        <p className="emision-wizard__hint">Buscando documentos emitidos…</p>
      ) : resultados.length === 0 ? (
        <p className="emision-wizard__hint">
          {query.trim()
            ? 'No hay DTE emitidos que coincidan.'
            : 'Escriba folio o receptor, o deje vacío para ver los más recientes.'}
        </p>
      ) : (
        <div className="emision-referencia-buscar__scroll">
          <table className="data-table data-table--readonly emision-referencia-buscar__table">
            <thead>
              <tr>
                <th>Folio</th>
                <th>Fecha</th>
                <th>Receptor</th>
                <th>Total</th>
                <th>Uso previo</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {resultados.map((documento) => (
                <tr key={documento.id}>
                  <td>{documento.folio}</td>
                  <td>{formatDocumentoFechaSolo(documento.fecha_emision)}</td>
                  <td>
                    {documento.razon_social_receptor}
                    <span className="emision-referencia-buscar__rut"> ({documento.rut_receptor})</span>
                  </td>
                  <td>{formatDocumentoMonto(documento.total)}</td>
                  <td>
                    {documento.referenciado_en.length > 0
                      ? documento.referenciado_en
                          .map(
                            (uso) =>
                              `${uso.tipo_documento} folio ${uso.folio}`,
                          )
                          .join(', ')
                      : '—'}
                  </td>
                  <td>
                    <Button
                      type="button"
                      variant="secondary"
                      disabled={disabled}
                      onClick={() => onSelect(documento)}
                    >
                      Usar
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
