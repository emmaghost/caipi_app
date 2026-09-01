-- =============================================================================
-- Planes de cotización: pago anticipado y pago con recargo (12 / 11 / 10)
-- Ejecutar en Supabase → SQL Editor
-- Si no corres este script, la app calcula mensualidad × meses.
-- =============================================================================

ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS costo_anticipado_12 NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS costo_anticipado_11 NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS costo_anticipado_10 NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS costo_recargo_12 NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS costo_recargo_11 NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS costo_recargo_10 NUMERIC(10,2);

COMMENT ON COLUMN public.configuracion_costos.costo_anticipado_12 IS
  'Pago único del ciclo plan 12. Null = mensualidad × 12';
COMMENT ON COLUMN public.configuracion_costos.costo_anticipado_11 IS
  'Pago único del ciclo plan 11. Null = mensualidad × 11';
COMMENT ON COLUMN public.configuracion_costos.costo_anticipado_10 IS
  'Pago único del ciclo plan 10. Null = mensualidad × 10';
COMMENT ON COLUMN public.configuracion_costos.costo_recargo_12 IS
  'Total mes a mes plan 12. Null = mensualidad × 12';
COMMENT ON COLUMN public.configuracion_costos.costo_recargo_11 IS
  'Total mes a mes plan 11. Null = mensualidad × 11';
COMMENT ON COLUMN public.configuracion_costos.costo_recargo_10 IS
  'Total mes a mes plan 10. Null = mensualidad × 10';
