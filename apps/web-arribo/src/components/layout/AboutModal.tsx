import { useEffect, useId, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { Loader2 } from 'lucide-react'
import { BrandLogo } from '@/components/brand/BrandLogo'
import { Button } from '@/components/ui/Button'
import {
  aboutConfig,
  getAppVersion,
  getBuildDateLabel,
} from '@/config/about'
import { fetchApiVersion } from '@/services/systemService'

interface AboutModalProps {
  isOpen: boolean
  onClose: () => void
}

export function AboutModal({ isOpen, onClose }: AboutModalProps) {
  const closeRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()
  const descriptionId = useId()
  const portalVersion = getAppVersion()
  const buildDate = getBuildDateLabel()
  const [apiVersion, setApiVersion] = useState<string | null>(null)
  const [apiVersionError, setApiVersionError] = useState(false)
  const [isLoadingApiVersion, setIsLoadingApiVersion] = useState(false)

  useEffect(() => {
    if (!isOpen) {
      return
    }

    closeRef.current?.focus()

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose()
      }
    }

    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [isOpen, onClose])

  useEffect(() => {
    if (!isOpen) {
      setApiVersion(null)
      setApiVersionError(false)
      setIsLoadingApiVersion(false)
      return
    }

    let cancelled = false
    setIsLoadingApiVersion(true)
    setApiVersionError(false)

    void fetchApiVersion()
      .then((version) => {
        if (!cancelled) {
          setApiVersion(version)
        }
      })
      .catch(() => {
        if (!cancelled) {
          setApiVersionError(true)
        }
      })
      .finally(() => {
        if (!cancelled) {
          setIsLoadingApiVersion(false)
        }
      })

    return () => {
      cancelled = true
    }
  }, [isOpen])

  if (!isOpen) {
    return null
  }

  function renderApiVersion() {
    if (isLoadingApiVersion) {
      return (
        <span className="about-modal__loading">
          <Loader2 className="about-modal__loading-icon animate-spin" aria-hidden="true" />
          Consultando…
        </span>
      )
    }

    if (apiVersionError) {
      return 'No disponible'
    }

    return apiVersion ?? '—'
  }

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal-dialog modal-dialog--about"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descriptionId}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="about-modal__brand">
          <BrandLogo variant="light" className="h-10 w-auto max-w-[220px]" />
          <p className="about-modal__subtitle">{aboutConfig.productSubtitle}</p>
        </div>

        <h2 id={titleId} className="modal-dialog__title about-modal__title">
          Acerca de {aboutConfig.productName}
        </h2>

        <div id={descriptionId} className="about-modal__details">
          <dl className="about-modal__list">
            <div className="about-modal__row">
              <dt>Versión del portal</dt>
              <dd>{portalVersion}</dd>
            </div>
            <div className="about-modal__row">
              <dt>Versión de la API</dt>
              <dd>{renderApiVersion()}</dd>
            </div>
            {buildDate ? (
              <div className="about-modal__row">
                <dt>Compilación del portal</dt>
                <dd>{buildDate}</dd>
              </div>
            ) : null}
            <div className="about-modal__row">
              <dt>Desarrollado por</dt>
              <dd>{aboutConfig.developerName}</dd>
            </div>
          </dl>

          <p className="about-modal__description">{aboutConfig.developerDescription}</p>
          <p className="about-modal__copyright">
            © {aboutConfig.copyrightYear} {aboutConfig.developerName}
          </p>
        </div>

        <div className="modal-dialog__actions">
          <Button ref={closeRef} type="button" onClick={onClose}>
            Cerrar
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  )
}

