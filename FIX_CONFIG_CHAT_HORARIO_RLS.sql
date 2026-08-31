-- =============================================================================
-- FIX: guardar horario del chat (RLS 42501 en config_chat_horario)
-- Ejecutar en Supabase → SQL Editor.
--
-- Síntoma: "new row violates row-level security policy for table config_chat_horario"
-- Causa: la app hace UPSERT y solo existía política UPDATE (sin INSERT / WITH CHECK).
-- =============================================================================

-- Misma helper que en FIX_PROFESORES_RLS_INSERT (idempotente)
CREATE OR REPLACE FUNCTION public.caipi_es_directora_o_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin')
  );
$$;

REVOKE ALL ON FUNCTION public.caipi_es_directora_o_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.caipi_es_directora_o_admin() TO authenticated;

-- Asegurar fila única
INSERT INTO public.config_chat_horario (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.config_chat_horario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS config_chat_horario_select ON public.config_chat_horario;
DROP POLICY IF EXISTS config_chat_horario_update ON public.config_chat_horario;
DROP POLICY IF EXISTS config_chat_horario_insert ON public.config_chat_horario;
DROP POLICY IF EXISTS config_chat_horario_upsert_staff ON public.config_chat_horario;

CREATE POLICY config_chat_horario_select ON public.config_chat_horario
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY config_chat_horario_insert ON public.config_chat_horario
  FOR INSERT TO authenticated
  WITH CHECK (public.caipi_es_directora_o_admin());

CREATE POLICY config_chat_horario_update ON public.config_chat_horario
  FOR UPDATE TO authenticated
  USING (public.caipi_es_directora_o_admin())
  WITH CHECK (public.caipi_es_directora_o_admin());
