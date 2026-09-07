-- =============================================================================
-- Bitácora diaria: ¿hubo incidencia? + tipo (texto libre)
-- Ejecutar en Supabase → SQL Editor → Run
-- =============================================================================

ALTER TABLE public.bitacora_diaria
  ADD COLUMN IF NOT EXISTS hubo_incidencia boolean NOT NULL DEFAULT false;

ALTER TABLE public.bitacora_diaria
  ADD COLUMN IF NOT EXISTS tipo_incidencia text;

COMMENT ON COLUMN public.bitacora_diaria.hubo_incidencia IS
  '¿Hubo alguna incidencia durante el día?';
COMMENT ON COLUMN public.bitacora_diaria.tipo_incidencia IS
  'Descripción breve del tipo de incidencia (solo si hubo_incidencia = true)';

-- Si no hubo incidencia, limpia el texto (opcional, por consistencia)
CREATE OR REPLACE FUNCTION public.bitacora_limpiar_incidencia()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.hubo_incidencia IS NOT TRUE THEN
    NEW.tipo_incidencia := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bitacora_limpiar_incidencia ON public.bitacora_diaria;
CREATE TRIGGER trg_bitacora_limpiar_incidencia
  BEFORE INSERT OR UPDATE ON public.bitacora_diaria
  FOR EACH ROW
  EXECUTE FUNCTION public.bitacora_limpiar_incidencia();
