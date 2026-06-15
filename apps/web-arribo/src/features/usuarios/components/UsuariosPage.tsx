import { AppLayout } from '@/components/layout/AppLayout'

export function UsuariosPage() {
  return (
    <AppLayout>
      <div className="page-header">
        <div>
          <h1>Usuarios</h1>
          <p className="page-header__subtitle">
            La administración de usuarios estará disponible próximamente.
          </p>
        </div>
      </div>

      <section className="panel-card">
        <p className="placeholder">
          Desde aquí podrás gestionar usuarios, roles y asignación a empresas.
        </p>
      </section>
    </AppLayout>
  )
}
