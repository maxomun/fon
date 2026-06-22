import { useCallback, useEffect, useState } from 'react'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, ConfirmDialog, Input } from '@/components/ui'
import { UsuarioDetalleModal } from '@/features/usuarios/components/UsuarioDetalleModal'
import { UsuarioFormModal } from '@/features/usuarios/components/UsuarioFormModal'
import { UsuarioRowActions } from '@/features/usuarios/components/UsuarioRowActions'
import { usuariosService } from '@/features/usuarios/services/usuariosService'
import type {
  Usuario,
  UsuarioCreateInput,
  UsuarioTipoFiltro,
  UsuarioUpdateInput,
} from '@/features/usuarios/types/usuario.types'
import { usuarioRolesLabel, usuarioTipoLabel } from '@/features/usuarios/types/usuario.types'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { ApiError } from '@/services/apiClient'

type FormMode = 'create' | 'edit' | null

const TIPO_OPCIONES: { value: UsuarioTipoFiltro; label: string }[] = [
  { value: 'todos', label: 'Todos' },
  { value: 'plataforma', label: 'Plataforma' },
  { value: 'persona', label: 'Persona autorizada' },
]

export function UsuariosPage() {
  const { user: currentUser } = useAuth()
  const [usuarios, setUsuarios] = useState<Usuario[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [listError, setListError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [tipoFiltro, setTipoFiltro] = useState<UsuarioTipoFiltro>('plataforma')

  const [formMode, setFormMode] = useState<FormMode>(null)
  const [selectedUsuario, setSelectedUsuario] = useState<Usuario | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const [detalleUsuario, setDetalleUsuario] = useState<Usuario | null>(null)
  const [isDetalleOpen, setIsDetalleOpen] = useState(false)
  const [isDetalleLoading, setIsDetalleLoading] = useState(false)
  const [detalleError, setDetalleError] = useState<string | null>(null)

  const [usuarioEstadoTarget, setUsuarioEstadoTarget] = useState<Usuario | null>(null)
  const [isUpdatingEstado, setIsUpdatingEstado] = useState(false)
  const [estadoError, setEstadoError] = useState<string | null>(null)
  const [updatingEstadoId, setUpdatingEstadoId] = useState<number | null>(null)

  const [reenviandoAccesoId, setReenviandoAccesoId] = useState<number | null>(null)

  const loadUsuarios = useCallback(async () => {
    setListError(null)
    setIsLoading(true)

    try {
      const response = await usuariosService.list(searchQuery, tipoFiltro)
      setUsuarios(response.data)
    } catch (error) {
      setListError(
        error instanceof ApiError ? error.message : 'No se pudieron cargar los usuarios',
      )
    } finally {
      setIsLoading(false)
    }
  }, [searchQuery, tipoFiltro])

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadUsuarios()
    }, 300)

    return () => window.clearTimeout(timeout)
  }, [loadUsuarios])

  function openCreateModal() {
    setSelectedUsuario(null)
    setFormError(null)
    setFormMode('create')
  }

  function openEditModal(usuario: Usuario) {
    setSelectedUsuario(usuario)
    setFormError(null)
    setFormMode('edit')
  }

  function closeFormModal() {
    setFormMode(null)
    setSelectedUsuario(null)
    setFormError(null)
  }

  async function handleCreate(values: UsuarioCreateInput) {
    setIsSubmitting(true)
    setFormError(null)

    try {
      const response = await usuariosService.create(values)
      setSuccessMessage(response.message ?? 'Operador creado exitosamente')
      closeFormModal()
      await loadUsuarios()
    } catch (error) {
      setFormError(
        error instanceof ApiError ? error.message : 'No se pudo crear el operador',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleUpdate(values: UsuarioUpdateInput) {
    if (!selectedUsuario) {
      return
    }

    setIsSubmitting(true)
    setFormError(null)

    try {
      const response = await usuariosService.update(selectedUsuario.id, values)
      setSuccessMessage(response.message ?? 'Usuario actualizado exitosamente')
      closeFormModal()
      await loadUsuarios()
    } catch (error) {
      setFormError(
        error instanceof ApiError ? error.message : 'No se pudo actualizar el usuario',
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  async function openDetalleModal(usuario: Usuario) {
    setDetalleUsuario(usuario)
    setIsDetalleOpen(true)
    setDetalleError(null)
    setIsDetalleLoading(true)

    try {
      const response = await usuariosService.get(usuario.id)
      setDetalleUsuario(response.data)
    } catch (error) {
      setDetalleError(
        error instanceof ApiError ? error.message : 'No se pudo cargar el detalle',
      )
    } finally {
      setIsDetalleLoading(false)
    }
  }

  function closeDetalleModal() {
    setIsDetalleOpen(false)
    setDetalleUsuario(null)
    setDetalleError(null)
  }

  function openEstadoConfirm(usuario: Usuario) {
    setEstadoError(null)
    setUsuarioEstadoTarget(usuario)
  }

  function closeEstadoConfirm() {
    setUsuarioEstadoTarget(null)
    setEstadoError(null)
  }

  async function confirmToggleEstado() {
    if (!usuarioEstadoTarget) {
      return
    }

    const nuevoActivo = !usuarioEstadoTarget.activo
    setIsUpdatingEstado(true)
    setUpdatingEstadoId(usuarioEstadoTarget.id)
    setEstadoError(null)

    try {
      const response = await usuariosService.setEstado(usuarioEstadoTarget.id, nuevoActivo)
      setSuccessMessage(
        response.message ??
          (nuevoActivo ? 'Usuario activado exitosamente' : 'Usuario desactivado exitosamente'),
      )
      closeEstadoConfirm()
      await loadUsuarios()
    } catch (error) {
      setEstadoError(
        error instanceof ApiError ? error.message : 'No se pudo cambiar el estado del usuario',
      )
    } finally {
      setIsUpdatingEstado(false)
      setUpdatingEstadoId(null)
    }
  }

  async function handleReenviarAcceso(usuario: Usuario) {
    setReenviandoAccesoId(usuario.id)
    setSuccessMessage(null)

    try {
      const response = await usuariosService.reenviarAcceso(usuario.id)
      setSuccessMessage(response.message ?? 'Acceso reenviado exitosamente')
    } catch (error) {
      setListError(
        error instanceof ApiError ? error.message : 'No se pudo reenviar el acceso',
      )
    } finally {
      setReenviandoAccesoId(null)
    }
  }

  const estadoConfirmTitle = usuarioEstadoTarget?.activo
    ? 'Desactivar usuario'
    : 'Activar usuario'

  const estadoConfirmMessage = usuarioEstadoTarget?.activo
    ? `¿Desactivar a ${usuarioEstadoTarget.nombre_completo ?? usuarioEstadoTarget.email}? No podrá iniciar sesión hasta que se reactive.`
    : `¿Activar a ${usuarioEstadoTarget?.nombre_completo ?? usuarioEstadoTarget?.email}?`

  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Usuarios de plataforma</h1>
          <p className="page-header__subtitle">
            Operadores con acceso global a FacturaOn. Las personas autorizadas de empresas se
            gestionan desde cada empresa.
          </p>
        </div>
        <Button onClick={openCreateModal}>Nuevo operador</Button>
      </div>

      {successMessage ? <Alert variant="success">{successMessage}</Alert> : null}

      {listError ? <Alert variant="error">{listError}</Alert> : null}

      <div className="page-toolbar">
        <Input
          label="Buscar"
          name="q"
          placeholder="Nombre, email o username…"
          value={searchQuery}
          onChange={(event) => setSearchQuery(event.target.value)}
          className="page-toolbar__search"
        />
        <div className="page-toolbar__filters">
          <span className="page-toolbar__filters-label">Tipo:</span>
          {TIPO_OPCIONES.map((opcion) => (
            <button
              key={opcion.value}
              type="button"
              className={`filter-chip ${tipoFiltro === opcion.value ? 'filter-chip--active' : ''}`}
              onClick={() => setTipoFiltro(opcion.value)}
            >
              {opcion.label}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <p className="page-loading">Cargando usuarios…</p>
      ) : usuarios.length === 0 ? (
        <p className="page-empty">No hay usuarios que coincidan con los filtros.</p>
      ) : (
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Email</th>
                <th>Rol</th>
                <th>Tipo</th>
                <th>Estado</th>
                <th aria-label="Acciones" />
              </tr>
            </thead>
            <tbody>
              {usuarios.map((usuario) => (
                <tr key={usuario.id}>
                  <td>{usuario.nombre_completo ?? '—'}</td>
                  <td>{usuario.email}</td>
                  <td>{usuarioRolesLabel(usuario)}</td>
                  <td>
                    <span
                      className={`badge ${
                        usuario.tipo_cuenta === 'plataforma' ? 'badge--info' : 'badge--neutral'
                      }`}
                    >
                      {usuarioTipoLabel(usuario.tipo_cuenta)}
                    </span>
                  </td>
                  <td>
                    <span
                      className={`badge ${usuario.activo ? 'badge--success' : 'badge--muted'}`}
                    >
                      {usuario.activo ? 'Activo' : 'Inactivo'}
                    </span>
                  </td>
                  <td className="data-table__actions">
                    <UsuarioRowActions
                      usuario={usuario}
                      isCurrentUser={currentUser?.id === usuario.id}
                      isUpdatingEstado={updatingEstadoId === usuario.id}
                      isReenviandoAcceso={reenviandoAccesoId === usuario.id}
                      onEdit={openEditModal}
                      onVerDetalle={openDetalleModal}
                      onToggleEstado={openEstadoConfirm}
                      onReenviarAcceso={handleReenviarAcceso}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {formMode === 'create' ? (
        <UsuarioFormModal
          mode="create"
          isOpen
          isLoading={isSubmitting}
          error={formError}
          onClose={closeFormModal}
          onSubmit={handleCreate}
        />
      ) : null}

      {formMode === 'edit' && selectedUsuario ? (
        <UsuarioFormModal
          mode="edit"
          usuario={selectedUsuario}
          isOpen
          isLoading={isSubmitting}
          error={formError}
          onClose={closeFormModal}
          onSubmit={handleUpdate}
        />
      ) : null}

      <UsuarioDetalleModal
        usuario={detalleUsuario}
        isOpen={isDetalleOpen}
        isLoading={isDetalleLoading}
        error={detalleError}
        onClose={closeDetalleModal}
      />

      <ConfirmDialog
        isOpen={usuarioEstadoTarget !== null}
        title={estadoConfirmTitle}
        confirmLabel={usuarioEstadoTarget?.activo ? 'Desactivar' : 'Activar'}
        variant={usuarioEstadoTarget?.activo ? 'danger' : 'default'}
        isLoading={isUpdatingEstado}
        error={estadoError}
        onConfirm={() => void confirmToggleEstado()}
        onCancel={closeEstadoConfirm}
      >
        <p>{estadoConfirmMessage}</p>
      </ConfirmDialog>
    </AppLayout>
  )
}
