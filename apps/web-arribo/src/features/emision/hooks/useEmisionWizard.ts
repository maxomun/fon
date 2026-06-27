import { useCallback, useEffect, useMemo, useState } from 'react'
import { dteService } from '@/features/emision/services/dteService'
import {
  emptyEmisionLinea,
  emptyEmisionReceptor,
  FACTURA_ELECTRONICA_CODIGO,
  type EmisionGenerarResponse,
  type EmisionLinea,
  type EmisionReceptor,
} from '@/features/emision/types/emision.types'
import {
  calcularTotalesEmision,
  resolverLineasCalculadas,
} from '@/features/emision/utils/calcularTotalesEmision'
import {
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

export function useEmisionWizard(empresaId: number) {
  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [productos, setProductos] = useState<Producto[]>([])
  const [tipoFactura, setTipoFactura] = useState<TipoHabilitado | null>(null)
  const [receptor, setReceptor] = useState<EmisionReceptor>(emptyEmisionReceptor())
  const [lineas, setLineas] = useState<EmisionLinea[]>([emptyEmisionLinea()])
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

  const totales = useMemo(
    () => calcularTotalesEmision(lineasCalculadas),
    [lineasCalculadas],
  )

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

  const emitir = useCallback(async () => {
    setFormError(null)
    setResultado(null)

    const errores = [...validarReceptor(receptor), ...validarLineas(lineas)]
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
  }, [empresaId, lineas, receptor, tipoFactura])

  const reiniciar = useCallback(() => {
    setReceptor(emptyEmisionReceptor())
    setLineas([emptyEmisionLinea()])
    setFormError(null)
    setResultado(null)
  }, [])

  return {
    empresa,
    productos,
    tipoFactura,
    receptor,
    setReceptor,
    lineas,
    lineasCalculadas,
    totales,
    isLoading,
    isSubmitting,
    pageError,
    formError,
    resultado,
    agregarLinea,
    quitarLinea,
    actualizarLinea,
    emitir,
    reiniciar,
  }
}
