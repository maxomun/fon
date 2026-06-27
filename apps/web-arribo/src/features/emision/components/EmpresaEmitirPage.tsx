import { Link, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, Button, LoadingScreen } from '@/components/ui'
import { useAuth } from '@/features/auth/hooks/useAuth'
import { hasAccesoGlobal } from '@/features/auth/utils/roles'
import { EmisionPrerrequisitosChecklist } from '@/features/emision/components/EmisionPrerrequisitosChecklist'
import { useEmisionPrerrequisitos } from '@/features/emision/hooks/useEmisionPrerrequisitos'

export function EmpresaEmitirPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)
  const { user } = useAuth()
  const isFonAdmin = hasAccesoGlobal(user)

  const { empresa, resultado, isLoading, isRefreshing, pageError, reload } =
    useEmisionPrerrequisitos(empresaId)

  if (isLoading) {
    return (
      <AppLayout>
        <LoadingScreen message="Verificando requisitos para emitir…" />
      </AppLayout>
    )
  }

  if (pageError) {
    return (
      <AppLayout>
        <div className="page-back-link">
          <Link to="/empresas">← Volver a empresas</Link>
        </div>
        <Alert variant="error">{pageError}</Alert>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
      </div>

      <header className="page-header">
        <div>
          <h1>Emitir documento tributario</h1>
          {empresa ? (
            <p className="page-header__subtitle">
              {empresa.razon_social} · RUT {empresa.rut}
            </p>
          ) : null}
        </div>
        <Link className="emision-checklist__link" to={`/empresas/${empresaId}/documentos`}>
          Ver documentos emitidos
        </Link>
      </header>

      {resultado.listoParaEmitir ? (
        <Alert variant="success">
          Todo listo. La empresa cumple los requisitos para emitir documentos electrónicos.
        </Alert>
      ) : (
        <Alert variant="info">
          Complete los requisitos pendientes antes de emitir. Faltan {resultado.pendientes}{' '}
          {resultado.pendientes === 1 ? 'paso' : 'pasos'}.
        </Alert>
      )}

      <section className="panel-card emision-panel">
        <div className="panel-card__title-row">
          <h2>Requisitos previos</h2>
          <div className="panel-card__refresh-indicator">
            {isRefreshing ? <span>Actualizando…</span> : null}
            <Button variant="secondary" onClick={() => void reload()} disabled={isRefreshing}>
              Volver a verificar
            </Button>
          </div>
        </div>

        <p className="emision-panel__intro">
          Antes de facturar, verifique que el catálogo, los tipos de documento, los folios CAF y
          los certificados digitales estén configurados.
        </p>

        <EmisionPrerrequisitosChecklist
          items={resultado.items}
          puedeGestionarCertificados={isFonAdmin}
        />
      </section>

      <section className="panel-card emision-panel__continuar">
        <h2>Siguiente paso</h2>
        <p className="emision-panel__intro">
          {resultado.listoParaEmitir
            ? 'Complete receptor e ítems para timbrar una Factura Electrónica (33).'
            : 'Cuando todos los requisitos estén en verde, podrá continuar al formulario de emisión.'}
        </p>
        {resultado.listoParaEmitir ? (
          <Link className="emision-checklist__link" to={`/empresas/${empresaId}/emitir/nuevo`}>
            Continuar a emitir
          </Link>
        ) : (
          <Button disabled title="Complete los requisitos previos">
            Continuar a emitir
          </Button>
        )}
      </section>
    </AppLayout>
  )
}
