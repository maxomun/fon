-- Tabla de auditoría (Sprint 1: infraestructura + auth)
-- Ejecutar manualmente en la BD de desarrollo/producción.
--
-- Ejemplo:
--   psql -U postgres -d facturaon_development -f db/manual/audit_events.sql
--
-- Rollback (solo si necesita deshacer):
--   DROP TABLE IF EXISTS audit_events;

BEGIN;

CREATE TABLE IF NOT EXISTS audit_events (
  id                    BIGSERIAL PRIMARY KEY,
  accion                VARCHAR(100) NOT NULL,
  categoria             VARCHAR(50)  NOT NULL,
  resultado             VARCHAR(20)  NOT NULL,
  actor_user_id         INTEGER,
  actor_email           VARCHAR(200),
  actor_nombre          VARCHAR(300),
  actor_acceso_global   BOOLEAN,
  empresa_id            INTEGER,
  recurso_tipo          VARCHAR(100),
  recurso_id            VARCHAR(100),
  recurso_label         VARCHAR(300),
  cambios               JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata              JSONB NOT NULL DEFAULT '{}'::jsonb,
  codigo_error          VARCHAR(100),
  mensaje               VARCHAR(500),
  ip                    VARCHAR(45),
  user_agent            VARCHAR(500),
  request_id            VARCHAR(100),
  created_at            TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_audit_events_resultado
    CHECK (resultado IN ('success', 'failure')),
  CONSTRAINT fk_audit_events_actor_user
    FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_audit_events_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE SET NULL
);

COMMENT ON TABLE audit_events IS 'Registro append-only de acciones críticas para auditoría.';
COMMENT ON COLUMN audit_events.accion IS 'Código de acción, ej. auth.login_exitoso';
COMMENT ON COLUMN audit_events.categoria IS 'Dominio: auth, usuarios, personas, empresa, certificados, folios, dte, catalogo';
COMMENT ON COLUMN audit_events.resultado IS 'success | failure';
COMMENT ON COLUMN audit_events.cambios IS 'Diff JSON de campos relevantes (sin secretos)';
COMMENT ON COLUMN audit_events.metadata IS 'Contexto adicional no sensible';
COMMENT ON COLUMN audit_events.empresa_id IS 'Scope tenant; NULL para eventos de plataforma';

CREATE INDEX IF NOT EXISTS idx_audit_events_created_at
  ON audit_events (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_events_empresa_created_at
  ON audit_events (empresa_id, created_at DESC)
  WHERE empresa_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audit_events_actor_created_at
  ON audit_events (actor_user_id, created_at DESC)
  WHERE actor_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audit_events_accion_created_at
  ON audit_events (accion, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_events_recurso
  ON audit_events (recurso_tipo, recurso_id);

COMMIT;
