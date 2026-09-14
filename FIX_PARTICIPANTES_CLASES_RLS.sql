-- =============================================================================
-- RLS participantes_clases — sin políticas la tabla queda inaccesible.
-- Ejecutar en Supabase → SQL Editor (seguro re-ejecutar).
-- =============================================================================

ALTER TABLE public.participantes_clases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "participantes_clases_select" ON public.participantes_clases;
DROP POLICY IF EXISTS "participantes_clases_staff_all" ON public.participantes_clases;
DROP POLICY IF EXISTS "Participantes clases visibles" ON public.participantes_clases;
DROP POLICY IF EXISTS "Directora gestiona participantes" ON public.participantes_clases;

CREATE POLICY "participantes_clases_select" ON public.participantes_clases
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN ('directora', 'profesor', 'profesor_admin', 'caja', 'secretaria')
    )
    OR EXISTS (
      SELECT 1 FROM public.alumnos a
      WHERE a.id = participantes_clases.alumno_id
        AND a.padre_id = auth.uid()
    )
  );

CREATE POLICY "participantes_clases_staff_all" ON public.participantes_clases
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN ('directora', 'caja', 'secretaria', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN ('directora', 'caja', 'secretaria', 'profesor_admin')
    )
  );

-- Asegurar que caja/secretaria puedan gestionar clases (si solo había directora)
DROP POLICY IF EXISTS "Directora gestiona clases extra" ON public.clases_extracurriculares;
DROP POLICY IF EXISTS "clases_extra_staff_all" ON public.clases_extracurriculares;

CREATE POLICY "clases_extra_staff_all" ON public.clases_extracurriculares
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN ('directora', 'caja', 'secretaria', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN ('directora', 'caja', 'secretaria', 'profesor_admin')
    )
  );

NOTIFY pgrst, 'reload schema';
