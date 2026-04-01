-- Ejecutar en Supabase SQL Editor (una vez).
-- Permite marcar "no asistió" y alinea el modelo con la app.

ALTER TABLE public.control_salidas
  ADD COLUMN IF NOT EXISTS ausente BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.control_salidas.ausente IS 'true = el niño no asistió ese día; sin hora_entrada/salida';
