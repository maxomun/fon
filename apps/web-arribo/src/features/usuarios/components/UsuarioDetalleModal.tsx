import { useEffect, useId, useRef } from 'react'
import { createPortal } from 'react-dom'
import { Button } from '@/components/ui'
import type { Usuario } from '@/features/usuarios/types/usuario.types'
import { usuarioRolesLabel, usuarioTipoLabel } from '@/features/usuarios/types/usuario.types'

interface UsuarioDetalleModalProps {
  usuario: Usuario | null
  isOpen: boolean
  isLoading: boolean
  error: string | null
  onClose: () => void
}

export function UsuarioDetalleModal({
  usuario,
  isOpen,
  isLoading,
  error,
  onClose,
}: UsuarioDetalleModalProps) {
  const closeRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()

  useEffect(() => {
    if (!isOpen) {
      return
    }

    closeRef.current?.focus()

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape' && !isLoading) {
        onClose()
      }
    }

    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [isOpen, isLoading, onClose])

  if (!isOpen) {
    return null
  }

  function handleBackdropClick() {
    if (!isLoading) {
      onClose()
    }
  }

  const persona = usuario?.persona_autorizada

  return createPortal(
    <div className="modal-overlay" onClick={handleBackdropClick}>
      <div
        className="modal-dialog modal-dialog--form"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <h2 id={titleId} className="modal-dialog__title">
          {usuario?.nombre_completo ?? usuario?.email ?? 'Detalle de usuario'}
        </h2>

        {isLoading ? (
          <p className="page-loading">Cargando detalle…</p>
        ) : error ? (
          <p className="modal-dialog__error">{error}</p>
        ) : usuario ? (
          <div className="usuario-detalle">
            <dl className="usuario-detalle__grid">
              <div>
                <dt>Email</dt>
                <dd>{usuario.email}</dd>
              </div>
              <div>
                <dt>Tipo de cuenta</dt>
                <dd>
                  <span className="badge badge--neutral">{usuarioTipoLabel(usuario.tipo_cuenta)}</span>
                </dd>
              </div>
              <div>
                <dt>Estado</dt>
                <dd>
                  <span className={`badge ${usuario.activo ? 'badge--success' : 'badge--muted'}`}>
                    {usuario.activo ? 'Activo' : 'Inactivo'}
                  </span>
                </dd>
              </div>
              <div>
                <dt>Rol</dt>
                <dd>{usuarioRolesLabel(usuario)}</dd>
              </div>
            </dl>

            {persona ? (
              <>
                <h3 className="usuario-detalle__subtitle">Persona autorizada</h3>
                <dl className="usuario-detalle__grid">
                  <div>
                    <dt>RUT</dt>
                    <dd>{persona.rut}</dd>
                  </div>
                  <div>
                    <dt>Nombre</dt>
                    <dd>{persona.nombre_completo}</dd>
                  </div>
                  <div>
                    <dt>Email persona</dt>
                    <dd>{persona.email}</dd>
                  </div>
                </dl>

                {persona.empresas.length > 0 ? (
                  <>
                    <h3 className="usuario-detalle__subtitle">Empresas asignadas</h3>
                    <ul className="usuario-detalle__empresas">
                      {persona.empresas.map((empresa) => (
                        <li key={empresa.id}>
                          <strong>{empresa.razon_social}</strong>
                          <span className="usuario-detalle__empresa-rut">{empresa.rut}</span>
                          {empresa.es_administrador_empresa ? (
                            <span className="badge badge--info">Admin empresa</span>
                          ) : null}
                        </li>
                      ))}
                    </ul>
                  </>
                ) : (
                  <p className="usuario-detalle__hint">
                    Sin empresas asignadas. Gestione esta persona desde el módulo de empresas.
                  </p>
                )}
              </>
            ) : null}

            {usuario.tipo_cuenta === 'persona_autorizada' ? (
              <p className="usuario-detalle__hint">
                Este usuario se gestiona desde Personas autorizadas en cada empresa.
              </p>
            ) : null}
          </div>
        ) : null}

        <div className="modal-dialog__actions">
          <Button ref={closeRef} type="button" onClick={onClose} disabled={isLoading}>
            Cerrar
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
