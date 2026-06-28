import { useEffect, useState, type FormEvent } from 'react'
import { Alert, Button } from '@/components/ui'
import { empresaLogoService } from '@/features/empresas/services/empresaLogoService'
import type { EmpresaLogoInfo } from '@/features/empresas/types/empresa.types'
import { emptyEmpresaLogo } from '@/features/empresas/types/empresa.types'
import {
  formatLogoByteSize,
  validateEmpresaLogoFile,
} from '@/features/empresas/utils/empresaLogoValidation'
import { ApiError } from '@/services/apiClient'

interface EmpresaLogoSectionProps {
  empresaId: number
  initialLogo?: EmpresaLogoInfo
  onLogoChange?: (logo: EmpresaLogoInfo) => void
}

export function EmpresaLogoSection({
  empresaId,
  initialLogo,
  onLogoChange,
}: EmpresaLogoSectionProps) {
  const [logo, setLogo] = useState<EmpresaLogoInfo>(initialLogo ?? emptyEmpresaLogo())
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [archivo, setArchivo] = useState<File | null>(null)
  const [isUploading, setIsUploading] = useState(false)
  const [isRemoving, setIsRemoving] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  useEffect(() => {
    setLogo(initialLogo ?? emptyEmpresaLogo())
  }, [initialLogo, empresaId])

  useEffect(() => {
    if (!logo.disponible) {
      setPreviewUrl(null)
      return
    }

    let objectUrl: string | null = null
    let cancelled = false

    async function loadPreview() {
      try {
        const { blob } = await empresaLogoService.fetchBlob(empresaId)
        if (cancelled) {
          return
        }

        objectUrl = URL.createObjectURL(blob)
        setPreviewUrl(objectUrl)
      } catch {
        if (!cancelled) {
          setPreviewUrl(null)
        }
      }
    }

    void loadPreview()

    return () => {
      cancelled = true
      if (objectUrl) {
        URL.revokeObjectURL(objectUrl)
      }
    }
  }, [empresaId, logo.disponible, logo.byte_size, logo.filename])

  function updateLogo(next: EmpresaLogoInfo) {
    setLogo(next)
    onLogoChange?.(next)
  }

  async function handleUpload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setActionError(null)
    setSuccessMessage(null)

    if (!archivo) {
      setActionError('Debe seleccionar una imagen')
      return
    }

    const validationError = await validateEmpresaLogoFile(archivo)
    if (validationError) {
      setActionError(validationError)
      return
    }

    setIsUploading(true)

    try {
      const response = await empresaLogoService.upload(empresaId, archivo)
      updateLogo(response.data)
      setArchivo(null)
      setSuccessMessage(response.message ?? 'Logo cargado correctamente')
    } catch (error) {
      setActionError(
        error instanceof ApiError ? error.message : 'No se pudo cargar el logo',
      )
    } finally {
      setIsUploading(false)
    }
  }

  async function handleRemove() {
    setActionError(null)
    setSuccessMessage(null)
    setIsRemoving(true)

    try {
      const response = await empresaLogoService.remove(empresaId)
      updateLogo(response.data)
      setArchivo(null)
      setSuccessMessage(response.message ?? 'Logo eliminado correctamente')
    } catch (error) {
      setActionError(
        error instanceof ApiError ? error.message : 'No se pudo eliminar el logo',
      )
    } finally {
      setIsRemoving(false)
    }
  }

  const isBusy = isUploading || isRemoving

  return (
    <section className="empresa-logo-section">
      <h3>Logo para PDF</h3>
      <p className="empresa-logo-section__hint">
        Imagen horizontal (~3:1), mínimo 180×60 px. Formatos PNG, JPEG o WebP (máx. 5 MB).
        Se optimiza automáticamente al subir.
      </p>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      <div className="empresa-logo-section__preview-row">
        <div className="empresa-logo-section__preview" aria-label="Vista previa del logo">
          {previewUrl ? (
            <img src={previewUrl} alt="Logo de la empresa" />
          ) : (
            <span>Sin logo</span>
          )}
        </div>

        {logo.disponible ? (
          <dl className="empresa-logo-section__meta">
            <div>
              <dt>Archivo</dt>
              <dd>{logo.filename ?? '—'}</dd>
            </div>
            {logo.byte_size != null ? (
              <div>
                <dt>Tamaño</dt>
                <dd>{formatLogoByteSize(logo.byte_size)}</dd>
              </div>
            ) : null}
          </dl>
        ) : null}
      </div>

      <form className="empresa-form" onSubmit={handleUpload}>
        <div className="empresa-form__grid">
          <div className="field">
            <label htmlFor="empresa-logo-archivo">Imagen</label>
            <input
              id="empresa-logo-archivo"
              type="file"
              accept="image/png,image/jpeg,image/webp,.png,.jpg,.jpeg,.webp"
              onChange={(event) => setArchivo(event.target.files?.[0] ?? null)}
              disabled={isBusy}
            />
          </div>
        </div>
        <div className="empresa-form__actions empresa-logo-section__actions">
          {logo.disponible ? (
            <Button
              type="button"
              variant="secondary"
              onClick={() => void handleRemove()}
              disabled={isBusy}
            >
              {isRemoving ? 'Eliminando…' : 'Eliminar logo'}
            </Button>
          ) : null}
          <Button type="submit" disabled={isBusy || !archivo}>
            {isUploading ? 'Subiendo…' : logo.disponible ? 'Reemplazar logo' : 'Subir logo'}
          </Button>
        </div>
      </form>
    </section>
  )
}
