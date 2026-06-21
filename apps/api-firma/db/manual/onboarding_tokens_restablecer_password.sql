-- Ampliar propósitos de onboarding_tokens para recuperación de contraseña
-- Ejecutar manualmente en la BD de desarrollo/producción

BEGIN;

ALTER TABLE onboarding_tokens
  DROP CONSTRAINT IF EXISTS chk_onboarding_tokens_proposito;

ALTER TABLE onboarding_tokens
  ADD CONSTRAINT chk_onboarding_tokens_proposito
  CHECK (
    proposito::text = ANY (
      ARRAY[
        'verificar_email'::character varying,
        'establecer_password'::character varying,
        'restablecer_password'::character varying
      ]::text[]
    )
  );

COMMIT;
