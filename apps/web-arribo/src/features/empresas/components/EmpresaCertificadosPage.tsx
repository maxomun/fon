import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDialog, Input } from '@/components/ui'
import { certificadosService } from '@/features/empresas/services/certificadosService'
import { empresaPersonasAutorizadasService } from '@/features/empresas/services/empresaPersonasAutorizadasService'
import { empresasService } from '@/features/empresas/services/empresasService'
import type { Certificado } from '@/features/empresas/types/certificado.types'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import type { PersonaAutorizada } from '@/features/empresas/types/personaAutorizada.types'
import { ApiError } from '@/services/apiClient'

function formatDate(value: string | null) {
  if (!value) {
    return '—'
  }

  return new Date(value).toLocaleDateString('es-CL')
}

function formatSiNo(value: boolean) {
  return value ? 'Sí' : 'No'
}

export function EmpresaCertificadosPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [personas, setPersonas] = useState<PersonaAutorizada[]>([])
  const [certificados, setCertificados] = useState<Certificado[]>([])
  const [selectedPersonaId, setSelectedPersonaId] = useState('')
  const [archivoCrs, setArchivoCrs] = useState<File | null>(null)
  const [archivoKey, setArchivoKey] = useState<File | null>(null)
  const [fraseClave, setFraseClave] = useState('')
  const [isLoading, setIsLoading] = useState(true)
  const [isUploading, setIsUploading] = useState(false)
  const [verifyingId, setVerifyingId] = useState<number | null>(null)
  const [certificadoToDeactivate, setCertificadoToDeactivate] = useState<Certificado | null>(
    null,
  )
  const [isDeactivating, setIsDeactivating] = useState(false)
  const [deactivateError, setDeactivateError] = useState<string | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const loadCertificados = useCallback(async () => {
    const response = await certificadosService.listByEmpresa(empresaId)
    setCertificados(response.data)
  }, [empresaId])

  const loadPage = useCallback(async () => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      setPageError('Empresa no válida')
      setIsLoading(false)
      return
    }

    setPageError(null)
    setIsLoading(true)

    try {
      const [empresaResponse, personasResponse, certificadosResponse] = await Promise.all([
        empresasService.get(empresaId),
        empresaPersonasAutorizadasService.listAssigned(empresaId),
        certificadosService.listByEmpresa(empresaId),
      ])

      setEmpresa(empresaResponse.data)
      setPersonas(personasResponse.data)
      setCertificados(certificadosResponse.data)
      setSelectedPersonaId((current) => {
        if (current) {
          return current
        }
        return personasResponse.data[0] ? String(personasResponse.data[0].id) : ''
      })
    } catch (error) {
      setPageError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar los certificados',
      )
    } finally {
      setIsLoading(false)
    }
  }, [empresaId])

  useEffect(() => {
    void loadPage()
  }, [loadPage])

  async function handleUpload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setActionError(null)
    setSuccessMessage(null)

    if (!selectedPersonaId) {
      setActionError('Seleccione una persona autorizada')
      return
    }

    if (!archivoCrs || !archivoKey) {
      setActionError('Debe adjuntar el certificado (.crt) y la clave privada (.key)')
      return
    }

    if (!fraseClave.trim()) {
      setActionError('La frase clave es requerida')
      return
    }

    setIsUploading(true)

    try {
      const response = await certificadosService.upload({
        personaAutorizadaId: Number(selectedPersonaId),
        empresaId,
        archivoCrs,
        archivoKey,
        fraseClave: fraseClave.trim(),
      })
      setSuccessMessage(response.message ?? 'Certificado cargado exitosamente')
      setArchivoCrs(null)
      setArchivoKey(null)
      setFraseClave('')
      await loadCertificados()
      await loadPage()
    } catch (error) {
      setActionError(
        error instanceof ApiError ? error.message : 'No se pudo cargar el certificado',
      )
    } finally {
      setIsUploading(false)
    }
  }

  async function handleVerify(certificado: Certificado) {
    setVerifyingId(certificado.id)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await certificadosService.verify(certificado.id)
      setSuccessMessage(response.message ?? 'Verificación completada')
      await loadCertificados()
    } catch (error) {
      setActionError(
        error instanceof ApiError ? error.message : 'No se pudo verificar el certificado',
      )
    } finally {
      setVerifyingId(null)
    }
  }

  function openDeactivateModal(certificado: Certificado) {
    setCertificadoToDeactivate(certificado)
    setDeactivateError(null)
  }

  function closeDeactivateModal() {
    setCertificadoToDeactivate(null)
    setDeactivateError(null)
    setIsDeactivating(false)
  }

  async function confirmDeactivate() {
    if (!certificadoToDeactivate) {
      return
    }

    setIsDeactivating(true)
    setDeactivateError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await certificadosService.deactivate(certificadoToDeactivate.id)
      setSuccessMessage(response.message ?? 'Certificado desactivado exitosamente')
      closeDeactivateModal()
      await loadCertificados()
      await loadPage()
    } catch (error) {
      setDeactivateError(
        error instanceof ApiError ? error.message : 'No se pudo desactivar el certificado',
      )
    } finally {
      setIsDeactivating(false)
    }
  }

  if (isLoading) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando certificados…</p>
      </AppLayout>
    )
  }

  if (pageError) {
    return (
      <AppLayout>
        <Alert variant="error">{pageError}</Alert>
        <p className="page-back-link">
          <Link to="/empresas">← Volver a empresas</Link>
        </p>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <p className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
        {' · '}
        <Link to={`/empresas/${empresaId}/personas-autorizadas`}>Personas autorizadas</Link>
      </p>

      <div className="page-header">
        <div>
          <h1>Certificados</h1>
          <p className="page-header__subtitle">
            {empresa?.razon_social ?? 'Empresa'} — certificados digitales para firmar DTE
          </p>
        </div>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      {personas.length === 0 ? (
        <div className="alert alert-error">
          Esta empresa no tiene personas autorizadas.{' '}
          <Link to={`/empresas/${empresaId}/personas-autorizadas`}>
            Asigne al menos una persona
          </Link>{' '}
          antes de cargar certificados.
        </div>
      ) : (
        <section className="panel-card actecos-search-panel">
          <h2>Cargar certificado</h2>
          <form className="empresa-form" onSubmit={handleUpload}>
            <div className="empresa-form__grid">
              <div className="field">
                <label htmlFor="persona-certificado">Persona autorizada</label>
                <select
                  id="persona-certificado"
                  className="select-input"
                  value={selectedPersonaId}
                  onChange={(event) => setSelectedPersonaId(event.target.value)}
                  required
                >
                  {personas.map((persona) => (
                    <option key={persona.id} value={persona.id}>
                      [{persona.orden}] {persona.nombre_completo} — {persona.rut}
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label htmlFor="archivo-crs">Certificado (.crt / .pem)</label>
                <input
                  id="archivo-crs"
                  type="file"
                  accept=".crt,.pem,.cer"
                  onChange={(event) => setArchivoCrs(event.target.files?.[0] ?? null)}
                  required
                />
              </div>
              <div className="field">
                <label htmlFor="archivo-key">Clave privada (.key / .pem)</label>
                <input
                  id="archivo-key"
                  type="file"
                  accept=".key,.pem"
                  onChange={(event) => setArchivoKey(event.target.files?.[0] ?? null)}
                  required
                />
              </div>
              <Input
                label="Frase clave"
                name="frase_clave"
                type="password"
                value={fraseClave}
                onChange={(event) => setFraseClave(event.target.value)}
                required
              />
            </div>
            <div className="empresa-form__actions">
              <Button type="submit" disabled={isUploading}>
                {isUploading ? 'Cargando…' : 'Cargar certificado'}
              </Button>
            </div>
          </form>
        </section>
      )}

      <section className="panel-card">
        <h2>Certificados registrados</h2>
        {certificados.length === 0 ? (
          <p className="placeholder">No hay certificados cargados para esta empresa.</p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Persona</th>
                  <th>Orden</th>
                  <th>Adjunción</th>
                  <th>Vigente</th>
                  <th>Completo</th>
                  <th>Útil para firma</th>
                  <th>Caducidad</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {certificados.map((certificado) => (
                  <tr key={certificado.id}>
                    <td>{certificado.persona.nombre_completo}</td>
                    <td>{certificado.persona.orden}</td>
                    <td>{formatDate(certificado.fecha_adjuncion)}</td>
                    <td>{formatSiNo(certificado.vigente)}</td>
                    <td>{formatSiNo(certificado.completo)}</td>
                    <td>{formatSiNo(certificado.utilizable_para_firma)}</td>
                    <td>{formatDate(certificado.fecha_caducacion)}</td>
                    <td>
                      <div className="table-actions">
                        <Button
                          variant="secondary"
                          disabled={verifyingId === certificado.id}
                          onClick={() => void handleVerify(certificado)}
                        >
                          {verifyingId === certificado.id ? 'Verificando…' : 'Verificar'}
                        </Button>
                        {certificado.vigente ? (
                          <Button
                            variant="secondary"
                            onClick={() => openDeactivateModal(certificado)}
                          >
                            Desactivar
                          </Button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <ConfirmDialog
        isOpen={certificadoToDeactivate !== null}
        title="Desactivar certificado"
        confirmLabel="Desactivar"
        variant="danger"
        isLoading={isDeactivating}
        error={deactivateError}
        onConfirm={confirmDeactivate}
        onCancel={closeDeactivateModal}
      >
        <p>
          ¿Desactivar el certificado de{' '}
          <strong>{certificadoToDeactivate?.persona.nombre_completo}</strong>?
        </p>
        <p>Podrá cargar un certificado nuevo para esa persona después.</p>
      </ConfirmDialog>
    </AppLayout>
  )
}
