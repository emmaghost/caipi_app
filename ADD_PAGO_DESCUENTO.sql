-- Descuento opcional en cargos (colegiatura, etc.)
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE pagos
  ADD COLUMN IF NOT EXISTS descuento NUMERIC(12, 2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN pagos.descuento IS
  'Descuento aplicado al monto bruto; monto en tabla ya es el neto a cobrar.';
