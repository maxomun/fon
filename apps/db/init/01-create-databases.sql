-- Bases adicionales para desarrollo local.
-- POSTGRES_DB (fon23_dev) ya la crea la imagen oficial al iniciar.

SELECT format('CREATE DATABASE %I', 'fon23_test')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'fon23_test')\gexec
