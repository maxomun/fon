import { useCallback, useEffect, useMemo, useState } from 'react'
import { dteService } from '@/features/emision/services/dteService'
import {
  emptyEmisionDescuentoRecargoGlobal,
  emptyEmisionLinea,
  emptyEmisionReceptor,
  FACTURA_ELECTRONICA_CODIGO,
  MAX_MOVIMIENTOS_GLOBALES,
  type EmisionDescuentoRecargoGlobal,
  type EmisionGenerarResponse,
  type EmisionLinea,
  type EmisionMovimientoGlobalCalculado,
  type EmisionReceptor,
  type EmisionTotales,
} from '@/features/emision/types/emision.types'
import {
  buildCalcularTotalesRequest,
  calcularTotalesEmision,
  mapearTotalesDesdeApi,
  resolverLineasCalculadas,
  serializarGlobalesParaApi,
} from '@/features/emision/utils/calcularTotalesEmision'
import {
  validarGlobales,
  validarLineas,
  validarReceptor,
} from '@/features/emision/utils/validarEmisionWizard'
import { empresaTiposHabilitadosService } from '@/features/empresas/services/empresaTiposHabilitadosService'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import type { TipoHabilitado } from '@/features/empresas/types/tipoHabilitado.types'
import { productosService } from '@/features/productos/services/productosService'
import type { Producto } from '@/features/productos/types/producto.types'
import { ApiError } from '@/services/apiClient'

const PREVIEW_DEBOUNCE_MS = 400

export function useEmisionWizard(empresaId: number) {
  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [productos, setProductos] = useState<Producto[]>([])
  const [tipoFactura, setTipoFactura] = useState<TipoHabilitado | null>(null)
  const [receptor, setReceptor] = useState<EmisionReceptor>(emptyEmisionReceptor())
  const [lineas, setLineas] = useState<EmisionLinea[]>([emptyEmisionLinea()])
  const [globales, setGlobales] = useState<EmisionDescuentoRecargoGlobal[]>([])
  const [movimientosCalculados, setMovimientosCalculados] = useState<
    EmisionMovimientoGlobalCalculado[]
  >([])
  const [totales, setTotales] = useState<EmisionTotales>(() => calcularTotalesEmision([]))
  const [totalesPreviewError, setTotalesPreviewError] = useState<string | null>(null)
  const [totalesCalculando, setTotalesCalculando] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [pageError, setPageError] = useState<string | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [resultado, setResultado] = useState<EmisionGenerarResponse | null>(null)

  const load = useCallback(async () => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      setPageError('Empresa no válida')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setPageError(null)

    try {
      const [empresaResponse, productosResponse, tiposResponse] = await Promise.all([
        empresasService.get(empresaId),
        productosService.list(empresaId, '', 'activos', 1),
        empresaTiposHabilitadosService.listAssigned(empresaId),
      ])

      const factura = tiposResponse.data.find(
        (tipo) => tipo.tipo_documento.codigo === FACTURA_ELECTRONICA_CODIGO,
      )

      if (!factura) {
        setPageError(
          'La empresa no tiene habilitada la Factura Electrónica (33). Configúrela en tipos de documento.',
        )
      }

      setEmpresa(empresaResponse.data)
      setProductos(productosResponse.data)
      setTipoFactura(factura ?? null)
    } catch (error) {
      const message =
        error instanceof ApiError
          ? error.message
          : 'No se pudo cargar la información para emitir.'
      setPageError(message)
    } finally {
      setIsLoading(false)
    }
  }, [empresaId])

  useEffect(() => {
    void load()
  }, [load])

  const lineasCalculadas = useMemo(
    () => resolverLineasCalculadas(lineas, productos),
    [lineas, productos],
  )

  const totalesLocales = useMemo(
    () => calcularTotalesEmision(lineasCalculadas),
    [lineasCalculadas],
  )

  useEffect(() => {
    const erroresLineas = validarLineas(lineas)
    if (erroresLineas.length > 0 || lineasCalculadas.length === 0) {
      setTotales(totalesLocales)
      setMovimientosCalculados([])
      setTotalesPreviewError(null)
      setTotalesCalculando(false)
      return
    }

    const erroresGlobalesParciales = validarGlobales(
      globales.filter((movimiento) => movimiento.valor.trim() !== ''),
    )
    if (erroresGlobalesParciales.length > 0) {
      setTotales(totalesLocales)
      setMovimientosCalculados([])
      setTotalesPreviewError(erroresGlobalesParciales[0] ?? null)
      setTotalesCalculando(false)
      return
    }

    let cancelado = false
    const timer = window.setTimeout(() => {
      void (async () => {
        setTotalesCalculando(true)
        try {
          const response = await dteService.calcularTotales(
            buildCalcularTotalesRequest(empresaId, lineas, receptor, globales),
          )

          if (cancelado) {
            return
          }

          if (response.success && response.data) {
            setTotales(mapearTotalesDesdeApi(response.data.totales))
            setMovimientosCalculados(response.data.descuentos_recargos_globales ?? [])
            setTotalesPreviewError(null)
            return
          }

          setTotales(totalesLocales)
          setMovimientosCalculados([])
          setTotalesPreviewError(
            response.errors?.join(' ') || response.error || 'No se pudo calcular totales.',
          )
        } catch (error) {
          if (cancelado) {
            return
          }

          setTotales(totalesLocales)
          setMovimientosCalculados([])
          setTotalesPreviewError(
            error instanceof ApiError ? error.message : 'No se pudo calcular totales.',
          )
        } finally {
          if (!cancelado) {
            setTotalesCalculando(false)
          }
        }
      })()
    }, PREVIEW_DEBOUNCE_MS)

    return () => {
      cancelado = true
      window.clearTimeout(timer)
    }
  }, [empresaId, globales, lineas, lineasCalculadas.length, receptor, totalesLocales])

  const agregarLinea = useCallback(() => {
    setLineas((current) => [...current, emptyEmisionLinea()])
  }, [])

  const quitarLinea = useCallback((key: string) => {
    setLineas((current) => {
      if (current.length <= 1) {
        return current
      }
      return current.filter((linea) => linea.key !== key)
    })
  }, [])

  const actualizarLinea = useCallback((key: string, patch: Partial<EmisionLinea>) => {
    setLineas((current) =>
      current.map((linea) => (linea.key === key ? { ...linea, ...patch } : linea)),
    )
  }, [])

  const agregarGlobal = useCallback(() => {
    setGlobales((current) => {
      if (current.length >= MAX_MOVIMIENTOS_GLOBALES) {
        return current
      }
      return [...current, emptyEmisionDescuentoRecargoGlobal()]
    })
  }, [])

  const quitarGlobal = useCallback((key: string) => {
    setGlobales((current) => current.filter((movimiento) => movimiento.key !== key))
  }, [])

  const actualizarGlobal = useCallback(
    (key: string, patch: Partial<EmisionDescuentoRecargoGlobal>) => {
      setGlobales((current) =>
        current.map((movimiento) =>
          movimiento.key === key ? { ...movimiento, ...patch } : movimiento,
        ),
      )
    },
    [],
  )

  const emitir = useCallback(async () => {
    setFormError(null)
    setResultado(null)

    const errores = [
      ...validarReceptor(receptor),
      ...validarLineas(lineas),
      ...validarGlobales(globales),
    ]
    if (errores.length > 0) {
      setFormError(errores.join(' '))
      return
    }

    if (!tipoFactura) {
      setFormError('No hay tipo de documento Factura Electrónica (33) habilitado.')
      return
    }

    setIsSubmitting(true)

    try {
      const globalesApi = serializarGlobalesParaApi(globales)

      const response = await dteService.generar({
        empresa_id: empresaId,
        tipo_documento: Number(FACTURA_ELECTRONICA_CODIGO),
        receptor: {
          rut: receptor.rut.trim(),
          razon_social: receptor.razon_social.trim(),
          giro: receptor.giro.trim(),
          direccion: receptor.direccion.trim(),
          email: receptor.email.trim(),
        },
        items: lineas.map((linea) => ({
          producto_id: linea.producto_id,
          cantidad: Number(linea.cantidad),
          descuento_pct: Number(linea.descuento_pct) || 0,
        })),
        ...(globalesApi.length > 0 ? { descuentos_recargos_globales: globalesApi } : {}),
        enviar_sii: false,
      })

      if (!response.success) {
        const detalle = response.errors?.join(' ') || response.error || 'No se pudo emitir el documento.'
        setFormError(response.fase ? `${detalle} (fase: ${response.fase})` : detalle)
        return
      }

      setResultado(response)
    } catch (error) {
      const message =
        error instanceof ApiError ? error.message : 'Error inesperado al emitir.'
      setFormError(message)
    } finally {
      setIsSubmitting(false)
    }
  }, [empresaId, globales, lineas, receptor, tipoFactura])

  const reiniciar = useCallback(() => {
    setReceptor(emptyEmisionReceptor())
    setLineas([emptyEmisionLinea()])
    setGlobales([])
    setMovimientosCalculados([])
    setFormError(null)
    setResultado(null)
    setTotalesPreviewError(null)
  }, [])

  return {
    empresa,
    productos,
    tipoFactura,
    receptor,
    setReceptor,
    lineas,
    lineasCalculadas,
    globales,
    movimientosCalculados,
    totales,
    totalesCalculando,
    totalesPreviewError,
    isLoading,
    isSubmitting,
    pageError,
    formError,
    resultado,
    agregarLinea,
    quitarLinea,
    actualizarLinea,
    agregarGlobal,
    quitarGlobal,
    actualizarGlobal,
    emitir,
    reiniciar,
  }
}
