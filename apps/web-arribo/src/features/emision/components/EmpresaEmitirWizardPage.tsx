import { Link, Navigate, useParams } from 'react-router-dom'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, LoadingScreen } from '@/components/ui'
import { EmisionLineasEditor } from '@/features/emision/components/EmisionLineasEditor'
import { EmisionReceptorForm } from '@/features/emision/components/EmisionReceptorForm'
import { EmisionResultadoPanel } from '@/features/emision/components/EmisionResultadoPanel'
import { EmisionWizardStickyFooter } from '@/features/emision/components/EmisionWizardStickyFooter'
import { useEmisionWizard } from '@/features/emision/hooks/useEmisionWizard'
import { FACTURA_ELECTRONICA_CODIGO } from '@/features/emision/types/emision.types'
import { rutaEmitirRequisitos } from '@/features/emision/utils/evaluarPrerrequisitos'

export function EmpresaEmitirWizardPage() {
  const { id } = useParams<{ id: string }>()
  const empresaId = Number(id)

  const {
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
  } = useEmisionWizard(empresaId)

  if (!Number.isFinite(empresaId) || empresaId <= 0) {
    return <Navigate to="/empresas" replace />
  }

  if (isLoading) {
    return (
      <AppLayout>
        <LoadingScreen message="Preparando formulario de emisión…" />
      </AppLayout>
    )
  }

  if (pageError) {
    return (
      <AppLayout>
        <div className="page-back-link">
          <Link to={rutaEmitirRequisitos(empresaId)}>← Volver</Link>
        </div>
        <Alert variant="error">{pageError}</Alert>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <div className="page-back-link">
        <Link to="/empresas">← Volver a empresas</Link>
        <Link className="emision-checklist__link" to={rutaEmitirRequisitos(empresaId)}>
          Ver requisitos
        </Link>
      </div>

      <header className="page-header">
        <h1>Emitir Factura Electrónica</h1>
        {empresa ? (
          <p className="page-header__subtitle">
            {empresa.razon_social} · RUT {empresa.rut}
          </p>
        ) : null}
      </header>

      <p className="emision-wizard__tipo-doc">
        Tipo de documento: <strong>{FACTURA_ELECTRONICA_CODIGO}</strong> — Factura
        Electrónica
        {tipoFactura ? (
          <span className="emision-wizard__folios">
            {' '}
            · {tipoFactura.folios_disponibles} folio
            {tipoFactura.folios_disponibles === 1 ? '' : 's'} disponible
            {tipoFactura.folios_disponibles === 1 ? '' : 's'}
          </span>
        ) : null}
      </p>

      {resultado?.success ? (
        <EmisionResultadoPanel
          empresaId={empresaId}
          resultado={resultado}
          onEmitirOtro={reiniciar}
        />
      ) : (
        <form
          className="emision-wizard emision-wizard--with-sticky-footer"
          onSubmit={(event) => {
            event.preventDefault()
            void emitir()
          }}
        >
          {formError ? <Alert variant="error">{formError}</Alert> : null}

          <section className="panel-card emision-wizard__section">
            <h2>Receptor</h2>
            <p className="emision-panel__intro">
              Datos del cliente que recibirá la factura. Por ahora se ingresan manualmente.
            </p>
            <EmisionReceptorForm
              value={receptor}
              disabled={isSubmitting}
              onChange={setReceptor}
            />
          </section>

          <section className="panel-card emision-wizard__section emision-wizard__section--lineas">
            <EmisionLineasEditor
              lineas={lineas}
              productos={productos}
              disabled={isSubmitting}
              onAdd={agregarLinea}
              onRemove={quitarLinea}
              onChange={actualizarLinea}
            />
          </section>

          <EmisionWizardStickyFooter
            totales={totales}
            cantidadItems={lineasCalculadas.length}
            isSubmitting={isSubmitting}
            canEmit={Boolean(tipoFactura)}
          />
        </form>
      )}
    </AppLayout>
  )
}
