-- =============================================================================
-- Secretaria: puede VER lista de alumnos + dar altas (sin beca en app)
-- Ejecutar si la secretaria entra a Alumnos y no aparece nadie.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.caipi_puede_alta_alumnos()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin', 'secretaria')
      AND COALESCE(activo, true) = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_puede_alta_alumnos() TO authenticated;

-- Unificar políticas de lectura (ADD_DOS_PADRES las dejó sin secretaria)
DROP POLICY IF EXISTS "alumnos_select" ON public.alumnos;
DROP POLICY IF EXISTS "Ver alumnos" ON public.alumnos;

CREATE POLICY "alumnos_select" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    public.caipi_puede_alta_alumnos()
    OR public.caipi_es_directora_o_admin()
    OR public.caipi_es_padre_de_alumno(id)
    OR padre_id = auth.uid()
    OR (
      to_regclass('public.alumnos_padres') IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.alumnos_padres ap
        WHERE ap.alumno_id = alumnos.id AND ap.padre_id = auth.uid()
      )
    )
    OR EXISTS (
      SELECT 1 FROM public.profesores p
      WHERE p.usuario_id = auth.uid()
        AND p.grado_id = alumnos.grado_id
        AND p.activo = true
    )
  );

DROP POLICY IF EXISTS "alumnos_insert" ON public.alumnos;
DROP POLICY IF EXISTS "alumnos_insert_directora_admin" ON public.alumnos;
CREATE POLICY "alumnos_insert" ON public.alumnos
  FOR INSERT TO authenticated
  WITH CHECK (public.caipi_puede_alta_alumnos());

DROP POLICY IF EXISTS "alumnos_update" ON public.alumnos;
DROP POLICY IF EXISTS "alumnos_update_directora_admin" ON public.alumnos;
CREATE POLICY "alumnos_update" ON public.alumnos
  FOR UPDATE TO authenticated
  USING (public.caipi_puede_alta_alumnos())
  WITH CHECK (public.caipi_puede_alta_alumnos());

-- Grados: lectura para quien da altas
DROP POLICY IF EXISTS "Ver grados" ON public.grados;
CREATE POLICY "Ver grados" ON public.grados
  FOR SELECT TO authenticated
  USING (true);

NOTIFY pgrst, 'reload schema';
