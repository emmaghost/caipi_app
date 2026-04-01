-- Varios grupos en un mismo registro de bitácora de gastos (Maternal + Kinder, etc.).
-- Ejecutar en Supabase → SQL Editor después de ADD_BITACORA_GASTOS.sql.

ALTER TABLE public.bitacora_gastos
  ADD COLUMN IF NOT EXISTS grupos_alcance_ids TEXT;

COMMENT ON COLUMN public.bitacora_gastos.grupos_alcance_ids IS
  'JSON array de UUID de grados cuando el gasto aplica a varios grupos. NULL si es un solo grado (grado_id) o toda la escuela.';
