-- =============================================================================
-- FIX: INSERT en tabla profesores (Row-Level Security 42501)
-- Ejecutar en Supabase → SQL Editor como postgres / service role.
--
-- Síntoma: "new row violates row-level security policy for table profesores"
-- Causas frecuentes:
--   1) No hay política FOR INSERT para directora
--   2) Política FOR ALL mal definida (falta WITH CHECK en INSERT)
--   3) Subconsulta a usuarios bloqueada por RLS (recursión)
-- =============================================================================

-- Función que evita recursión RLS al leer rol desde usuarios
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

ALTER TABLE public.profesores ENABLE ROW LEVEL SECURITY;

-- Quitar políticas antiguas / duplicadas (nombres usados en distintos scripts)
DROP POLICY IF EXISTS "Todos pueden ver profesores" ON public.profesores;
DROP POLICY IF EXISTS "Directora puede gestionar profesores" ON public.profesores;
DROP POLICY IF EXISTS "Ver profesores" ON public.profesores;
DROP POLICY IF EXISTS "Gestionar profesores" ON public.profesores;
DROP POLICY IF EXISTS "Directora puede insertar profesores" ON public.profesores;
DROP POLICY IF EXISTS "Directora puede actualizar profesores" ON public.profesores;
DROP POLICY IF EXISTS "profesores_select_authenticated" ON public.profesores;
DROP POLICY IF EXISTS "profesores_insert_directora" ON public.profesores;
DROP POLICY IF EXISTS "profesores_update_directora" ON public.profesores;
DROP POLICY IF EXISTS "profesores_delete_directora" ON public.profesores;

-- Cualquier usuario autenticado puede listar profesores (como ya hace la app)
CREATE POLICY "profesores_select_auth"
  ON public.profesores
  FOR SELECT
  TO authenticated
  USING (true);

-- Alta de profesoras desde la app (sesión = directora o profesor_admin)
CREATE POLICY "profesores_insert_staff"
  ON public.profesores
  FOR INSERT
  TO authenticated
  WITH CHECK (public.caipi_es_directora_o_admin());

CREATE POLICY "profesores_update_staff"
  ON public.profesores
  FOR UPDATE
  TO authenticated
  USING (public.caipi_es_directora_o_admin())
  WITH CHECK (public.caipi_es_directora_o_admin());

CREATE POLICY "profesores_delete_staff"
  ON public.profesores
  FOR DELETE
  TO authenticated
  USING (public.caipi_es_directora_o_admin());

-- Verificación rápida (opcional):
-- SELECT policyname, cmd, permissive FROM pg_policies WHERE tablename = 'profesores';
--
-- Si el alta SÍ queda en la BD pero la app mostraba error RLS:
--   - Suele ser política SELECT distinta a INSERT, o RETURNING del API.
--   - La app ya usa return=minimal y comprueba el alta.
-- Políticas RESTRICTIVE en profesores bloquean aunque otra política pase:
--   SELECT * FROM pg_policies WHERE tablename = 'profesores' AND permissive = 'RESTRICTIVE';
