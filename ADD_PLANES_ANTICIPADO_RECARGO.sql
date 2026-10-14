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
  'Monto POR MES del plan 12 si pagan 1 día antes. Null = misma mensualidad';
COMMENT ON COLUMN public.configuracion_costos.costo_anticipado_11 IS
  'Monto POR MES del plan 11 si pagan 1 día antes. Null = misma mensualidad';
COMMENT ON COLUMN public.configuracion_costos.costo_anticipado_10 IS
  'Monto POR MES del plan 10 si pagan 1 día antes. Null = misma mensualidad';
COMMENT ON COLUMN public.configuracion_costos.costo_recargo_12 IS
  'Monto POR MES del plan 12 desde el día 11. Null = misma mensualidad';
COMMENT ON COLUMN public.configuracion_costos.costo_recargo_11 IS
  'Monto POR MES del plan 11 desde el día 11. Null = misma mensualidad';
COMMENT ON COLUMN public.configuracion_costos.costo_recargo_10 IS
  'Monto POR MES del plan 10 desde el día 11. Null = misma mensualidad';

NOTIFY pgrst, 'reload schema';
