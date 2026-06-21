import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, Checkbox, ConfirmDialog, Input } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { hasAccesoGlobal } from '@/features/auth/utils/roles'
import { PersonaAutorizadaEditModal } from '@/features/empresas/components/PersonaAutorizadaEditModal'
import { PersonaAutorizadaOnboardingBadge } from '@/features/empresas/components/PersonaAutorizadaOnboardingBadge'
import { PersonaAutorizadaRowActions } from '@/features/empresas/components/PersonaAutorizadaRowActions'
import { empresaPersonasAutorizadasService } from '@/features/empresas/services/empresaPersonasAutorizadasService'
import { empresasService } from '@/features/empresas/services/empresasService'
import { personaAutorizadaService } from '@/features/empresas/services/personaAutorizadaService'
import type { Empresa } from '@/features/empresas/types/empresa.types'
import type {
  PersonaAutorizada,
  PersonaAutorizadaInput,
} from '@/features/empresas/types/personaAutorizada.types'
import {
  emptyPersonaAutorizadaInput,
  puedeEliminarPersonaAutorizada,
} from '@/features/empresas/types/personaAutorizada.types'
import { ApiError } from '@/services/apiClient'

function formatEstado(activa: boolean) {
  return activa ? 'Activa' : 'Inactiva'
}

export function EmpresaPersonasAutorizadasPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)
  const { user } = useAuth()
  const isFonAdmin = hasAccesoGlobal(user)

  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [assignedPersonas, setAssignedPersonas] = useState<PersonaAutorizada[]>([])
  const [searchResults, setSearchResults] = useState<PersonaAutorizada[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [assignAsAdmin, setAssignAsAdmin] = useState(false)
  const [createAssignAsAdmin, setCreateAssignAsAdmin] = useState(false)
  const [createValues, setCreateValues] = useState<PersonaAutorizadaInput>(
    emptyPersonaAutorizadaInput(),
  )
  const [isLoading, setIsLoading] = useState(true)
  const [isSearching, setIsSearching] = useState(false)
  const [isCreating, setIsCreating] = useState(false)
  const [assigningPersonaId, setAssigningPersonaId] = useState<number | null>(null)
  const [updatingAdminPersonaId, setUpdatingAdminPersonaId] = useState<number | null>(null)
  const [resendingOnboardingPersonaId, setResendingOnboardingPersonaId] = useState<number | null>(
    null,
  )
  const [personaToRemove, setPersonaToRemove] = useState<PersonaAutorizada | null>(null)
  const [personaToDelete, setPersonaToDelete] = useState<PersonaAutorizada | null>(null)
  const [personaToEdit, setPersonaToEdit] = useState<PersonaAutorizada | null>(null)
  const [isUpdating, setIsUpdating] = useState(false)
  const [updateError, setUpdateError] = useState<string | null>(null)
  const [isRemoving, setIsRemoving] = useState(false)
  const [removeError, setRemoveError] = useState<string | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  const loadAssigned = useCallback(async () => {
    const response = await empresaPersonasAutorizadasService.listAssigned(empresaId)
    setAssignedPersonas(response.data)
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
      const [empresaResponse, assignedResponse] = await Promise.all([
        empresasService.get(empresaId),
        empresaPersonasAutorizadasService.listAssigned(empresaId),
      ])

      setEmpresa(empresaResponse.data)
      setAssignedPersonas(assignedResponse.data)
    } catch (error) {
      setPageError(
        error instanceof ApiError
          ? error.message
          : 'No se pudieron cargar las personas autorizadas',
      )
    } finally {
      setIsLoading(false)
    }
  }, [empresaId])

  useEffect(() => {
    void loadPage()
  }, [loadPage])

  useEffect(() => {
    if (!Number.isFinite(empresaId) || empresaId <= 0) {
      return
    }

    const timeoutId = window.setTimeout(async () => {
      setIsSearching(true)
      setActionError(null)

      try {
        const response = await personaAutorizadaService.list(searchQuery, empresaId)
        setSearchResults(response.data)
      } catch (error) {
        setActionError(
          error instanceof ApiError
            ? error.message
            : 'No se pudo buscar personas autorizadas',
        )
      } finally {
        setIsSearching(false)
      }
    }, 300)

    return () => window.clearTimeout(timeoutId)
  }, [empresaId, searchQuery])

  async function handleAssign(persona: PersonaAutorizada) {
    setAssigningPersonaId(persona.id)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaPersonasAutorizadasService.assign(empresaId, persona.id, {
        esAdministradorEmpresa: assignAsAdmin,
      })
      setSuccessMessage(
        response.message ?? 'Persona autorizada asignada exitosamente',
      )
      await loadAssigned()
      setSearchResults((current) => current.filter((item) => item.id !== persona.id))
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo asignar la persona autorizada',
      )
    } finally {
      setAssigningPersonaId(null)
    }
  }

  async function handleCreate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setIsCreating(true)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const created = await personaAutorizadaService.create(createValues)
      await empresaPersonasAutorizadasService.assign(empresaId, created.data.id, {
        esAdministradorEmpresa: createAssignAsAdmin,
      })
      setSuccessMessage('Persona autorizada creada y asignada a la empresa')
      setCreateValues(emptyPersonaAutorizadaInput())
      setCreateAssignAsAdmin(false)
      await loadAssigned()
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo crear la persona autorizada',
      )
    } finally {
      setIsCreating(false)
    }
  }

  async function handleToggleAdmin(persona: PersonaAutorizada) {
    setUpdatingAdminPersonaId(persona.id)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const nextValue = !persona.es_administrador_empresa
      const response = await empresaPersonasAutorizadasService.updateAdminRole(
        empresaId,
        persona.id,
        nextValue,
      )
      setSuccessMessage(
        response.message ??
          (nextValue
            ? 'Persona marcada como administradora de la empresa'
            : 'Se quitó el rol de administrador de la empresa'),
      )
      await loadAssigned()
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo actualizar el rol de administrador',
      )
    } finally {
      setUpdatingAdminPersonaId(null)
    }
  }

  function syncPersonaInLists(updated: PersonaAutorizada) {
    setAssignedPersonas((current) =>
      current.map((item) => (item.id === updated.id ? updated : item)),
    )
    setSearchResults((current) =>
      current.map((item) => (item.id === updated.id ? updated : item)),
    )
  }

  async function handleReenviarOnboarding(persona: PersonaAutorizada) {
    setResendingOnboardingPersonaId(persona.id)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await personaAutorizadaService.reenviarOnboarding(persona.id)
      syncPersonaInLists(response.data)
      setSuccessMessage(
        response.message ?? 'Correo de enrolamiento reenviado exitosamente',
      )
    } catch (error) {
      setActionError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo reenviar el correo de enrolamiento',
      )
    } finally {
      setResendingOnboardingPersonaId(null)
    }
  }

  function openEditModal(persona: PersonaAutorizada) {
    setPersonaToEdit(persona)
    setUpdateError(null)
  }

  function closeEditModal() {
    setPersonaToEdit(null)
    setUpdateError(null)
    setIsUpdating(false)
  }

  async function handleUpdate(values: PersonaAutorizadaInput) {
    if (!personaToEdit) {
      return
    }

    setIsUpdating(true)
    setUpdateError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await personaAutorizadaService.update(personaToEdit.id, values)
      setSuccessMessage(response.message ?? 'Persona autorizada actualizada exitosamente')
      setSearchResults((current) =>
        current.map((item) => (item.id === response.data.id ? response.data : item)),
      )
      closeEditModal()
      await loadAssigned()
    } catch (error) {
      setUpdateError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo actualizar la persona autorizada',
      )
    } finally {
      setIsUpdating(false)
    }
  }

  function openRemoveModal(persona: PersonaAutorizada) {
    setPersonaToRemove(persona)
    setRemoveError(null)
  }

  function closeRemoveModal() {
    setPersonaToRemove(null)
    setRemoveError(null)
    setIsRemoving(false)
  }

  async function confirmRemove() {
    if (!personaToRemove) {
      return
    }

    setIsRemoving(true)
    setRemoveError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await empresaPersonasAutorizadasService.remove(
        empresaId,
        personaToRemove.id,
      )
      setSuccessMessage(
        response.message ?? 'Persona autorizada quitada de la empresa',
      )
      closeRemoveModal()
      await loadAssigned()
    } catch (error) {
      setRemoveError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo quitar la persona autorizada',
      )
    } finally {
      setIsRemoving(false)
    }
  }

  function openDeleteModal(persona: PersonaAutorizada) {
    setPersonaToDelete(persona)
    setDeleteError(null)
  }

  function closeDeleteModal() {
    setPersonaToDelete(null)
    setDeleteError(null)
    setIsDeleting(false)
  }

  async function confirmDelete() {
    if (!personaToDelete) {
      return
    }

    setIsDeleting(true)
    setDeleteError(null)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const response = await personaAutorizadaService.remove(personaToDelete.id)
      setSuccessMessage(response.message ?? 'Persona autorizada eliminada exitosamente')
      setSearchResults((current) => current.filter((item) => item.id !== personaToDelete.id))
      closeDeleteModal()
    } catch (error) {
      setDeleteError(
        error instanceof ApiError
          ? error.message
          : 'No se pudo eliminar la persona autorizada',
      )
    } finally {
      setIsDeleting(false)
    }
  }

  if (isLoading) {
    return (
      <AppLayout>
        <p className="placeholder">Cargando personas autorizadas…</p>
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
        {isFonAdmin ? (
          <>
            {' · '}
            <Link to={`/empresas/${empresaId}/certificados`}>Certificados</Link>
          </>
        ) : null}
      </p>

      <div className="page-header">
        <div>
          <h1>Personas autorizadas</h1>
          <p className="page-header__subtitle">
            {empresa?.razon_social ?? 'Empresa'} — representantes habilitados para firmar
          </p>
        </div>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}
      {actionError ? <Alert variant="error">{actionError}</Alert> : null}

      <section className="panel-card">
        <h2>Asignadas a esta empresa</h2>
        {assignedPersonas.length === 0 ? (
          <p className="placeholder">
            Esta empresa no tiene personas autorizadas asignadas.
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Orden</th>
                  <th>RUT</th>
                  <th>Nombre</th>
                  <th>Email</th>
                  <th>Estado</th>
                  <th>Certificado</th>
                  <th>Admin empresa</th>
                  <th>Enrolamiento</th>
                  <th>Acción</th>
                </tr>
              </thead>
              <tbody>
                {assignedPersonas.map((persona) => (
                  <tr key={persona.id}>
                    <td>{persona.orden}</td>
                    <td>{persona.rut}</td>
                    <td>{persona.nombre_completo}</td>
                    <td>{persona.email}</td>
                    <td>{formatEstado(persona.activa)}</td>
                    <td>{persona.tiene_certificado_vigente ? 'Vigente' : 'Sin certificado'}</td>
                    <td>
                      {persona.es_administrador_empresa ? (
                        <span className="badge badge--admin">Administrador</span>
                      ) : (
                        <span className="badge badge--neutral">Solo firma</span>
                      )}
                    </td>
                    <td>
                      <PersonaAutorizadaOnboardingBadge persona={persona} />
                    </td>
                    <td>
                      <PersonaAutorizadaRowActions
                        persona={persona}
                        variant="assigned"
                        isFonAdmin={isFonAdmin}
                        isUpdatingAdmin={updatingAdminPersonaId === persona.id}
                        isResendingOnboarding={resendingOnboardingPersonaId === persona.id}
                        onEdit={openEditModal}
                        onToggleAdmin={(item) => void handleToggleAdmin(item)}
                        onRemove={openRemoveModal}
                        onReenviarOnboarding={(item) => void handleReenviarOnboarding(item)}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="panel-card actecos-search-panel">
        <h2>Crear y asignar persona</h2>
        <form className="empresa-form" onSubmit={handleCreate}>
          <div className="empresa-form__grid">
            <Input
              label="RUT"
              name="rut"
              value={createValues.rut}
              onChange={(event) =>
                setCreateValues((current) => ({ ...current, rut: event.target.value }))
              }
              required
              maxLength={20}
            />
            <Input
              label="Nombres"
              name="nombres"
              value={createValues.nombres}
              onChange={(event) =>
                setCreateValues((current) => ({ ...current, nombres: event.target.value }))
              }
              required
            />
            <Input
              label="Apellido paterno"
              name="apellido_paterno"
              value={createValues.apellido_paterno}
              onChange={(event) =>
                setCreateValues((current) => ({
                  ...current,
                  apellido_paterno: event.target.value,
                }))
              }
            />
            <Input
              label="Apellido materno"
              name="apellido_materno"
              value={createValues.apellido_materno}
              onChange={(event) =>
                setCreateValues((current) => ({
                  ...current,
                  apellido_materno: event.target.value,
                }))
              }
            />
            <Input
              label="Email"
              name="email"
              type="email"
              value={createValues.email}
              onChange={(event) =>
                setCreateValues((current) => ({ ...current, email: event.target.value }))
              }
              required
            />
            <Input
              label="Orden de prioridad"
              name="orden"
              type="number"
              min={1}
              value={createValues.orden ?? 1}
              onChange={(event) =>
                setCreateValues((current) => ({
                  ...current,
                  orden: Number(event.target.value),
                }))
              }
              required
            />
          </div>
          <Checkbox
            name="create_assign_as_admin"
            label="Administrador de esta empresa"
            hint="Puede gestionar actecos, tipos de documento, folios y personas autorizadas."
            checked={createAssignAsAdmin}
            onChange={(event) => setCreateAssignAsAdmin(event.target.checked)}
          />
          <div className="empresa-form__actions">
            <Button type="submit" disabled={isCreating}>
              {isCreating ? 'Creando…' : 'Crear y asignar'}
            </Button>
          </div>
        </form>
      </section>

      <section className="panel-card actecos-search-panel">
        <h2>Asignar persona existente</h2>
        <Input
          label="Buscar por RUT, nombre o email"
          name="persona-search"
          value={searchQuery}
          onChange={(event) => setSearchQuery(event.target.value)}
          placeholder="Ej: 12345678-9 o juan@ejemplo.cl"
        />

        <Checkbox
          name="assign_as_admin"
          label="Asignar como administrador de esta empresa"
          hint="Si no se marca, la persona solo podrá firmar cuando tenga certificado vigente."
          checked={assignAsAdmin}
          onChange={(event) => setAssignAsAdmin(event.target.checked)}
        />

        {isSearching ? (
          <p className="placeholder">Buscando…</p>
        ) : searchResults.length === 0 ? (
          <p className="placeholder">
            {searchQuery.trim()
              ? 'No hay resultados para esa búsqueda.'
              : 'Escriba un término para buscar personas autorizadas.'}
          </p>
        ) : (
          <div className="data-table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Orden</th>
                  <th>RUT</th>
                  <th>Nombre</th>
                  <th>Email</th>
                  <th>Enrolamiento</th>
                  <th>Acción</th>
                </tr>
              </thead>
              <tbody>
                {searchResults.map((persona) => (
                  <tr key={persona.id}>
                    <td>{persona.orden}</td>
                    <td>{persona.rut}</td>
                    <td>{persona.nombre_completo}</td>
                    <td>{persona.email}</td>
                    <td>
                      <PersonaAutorizadaOnboardingBadge persona={persona} />
                    </td>
                    <td>
                      <PersonaAutorizadaRowActions
                        persona={persona}
                        variant="search"
                        isFonAdmin={isFonAdmin}
                        isAssigning={assigningPersonaId === persona.id}
                        isResendingOnboarding={resendingOnboardingPersonaId === persona.id}
                        onEdit={openEditModal}
                        onAssign={(item) => void handleAssign(item)}
                        onDelete={openDeleteModal}
                        onReenviarOnboarding={(item) => void handleReenviarOnboarding(item)}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <PersonaAutorizadaEditModal
        persona={personaToEdit}
        isOpen={personaToEdit !== null}
        isLoading={isUpdating}
        error={updateError}
        onClose={closeEditModal}
        onSubmit={handleUpdate}
      />

      <ConfirmDialog
        isOpen={personaToRemove !== null}
        title="Quitar persona autorizada"
        confirmLabel="Quitar"
        variant="danger"
        isLoading={isRemoving}
        error={removeError}
        onConfirm={confirmRemove}
        onCancel={closeRemoveModal}
      >
        <p>
          ¿Está seguro de quitar <strong>{personaToRemove?.nombre_completo}</strong> de
          esta empresa?
        </p>
        <p>La persona seguirá en el catálogo y podrá asignarse a otras empresas.</p>
      </ConfirmDialog>

      <ConfirmDialog
        isOpen={personaToDelete !== null}
        title="Eliminar persona autorizada"
        confirmLabel="Eliminar"
        variant="danger"
        isLoading={isDeleting}
        error={deleteError}
        onConfirm={confirmDelete}
        onCancel={closeDeleteModal}
      >
        <p>
          ¿Está seguro de eliminar permanentemente a{' '}
          <strong>{personaToDelete?.nombre_completo}</strong> del catálogo?
        </p>
        {personaToDelete && !puedeEliminarPersonaAutorizada(personaToDelete) ? (
          <p>Esta persona tiene empresas o certificados asociados y no puede eliminarse.</p>
        ) : (
          <p>Esta acción no se puede deshacer.</p>
        )}
      </ConfirmDialog>
    </AppLayout>
  )
}
