-- =============================================================================
-- FIX: Directora (y admin/caja/secretaria) SIEMPRE ven TODOS los alumnos
-- El filtro por grado solo aplica a rol = 'profesor' (maestra de aula).
-- Ejecutar en Supabase → SQL Editor → Run
-- =============================================================================

CREATE OR REPLACE FUNCTION public.caipi_rol_actual()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.rol
  FROM public.usuarios u
  WHERE u.id = auth.uid()
    AND COALESCE(u.activo, true) = true
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.caipi_rol_actual() TO authenticated;

CREATE OR REPLACE FUNCTION public.caipi_puede_ver_todos_alumnos()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.caipi_rol_actual() IN (
    'directora', 'profesor_admin', 'secretaria', 'caja'
  );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_puede_ver_todos_alumnos() TO authenticated;

CREATE OR REPLACE FUNCTION public.grados_de_profesor(p_usuario_id UUID DEFAULT auth.uid())
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT pg.grado_id
  FROM public.profesores p
  JOIN public.profesores_grados pg ON pg.profesor_id = p.id
  WHERE p.usuario_id = p_usuario_id
    AND p.activo = TRUE
  UNION
  SELECT p.grado_id
  FROM public.profesores p
  WHERE p.usuario_id = p_usuario_id
    AND p.activo = TRUE
    AND p.grado_id IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.grados_de_profesor(UUID) TO authenticated;

DROP POLICY IF EXISTS "alumnos_select" ON public.alumnos;
DROP POLICY IF EXISTS "Ver alumnos" ON public.alumnos;

CREATE POLICY "alumnos_select" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    -- Directora / supervisora / secretaria / caja: TODOS
    public.caipi_puede_ver_todos_alumnos()
    -- Padre
    OR padre_id = auth.uid()
    OR (
      to_regclass('public.alumnos_padres') IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.alumnos_padres ap
        WHERE ap.alumno_id = alumnos.id AND ap.padre_id = auth.uid()
      )
    )
    -- Solo maestra (rol profesor): sus grados
    OR (
      public.caipi_rol_actual() = 'profesor'
      AND alumnos.grado_id IN (
        SELECT public.grados_de_profesor(auth.uid())
      )
    )
  );

NOTIFY pgrst, 'reload schema';

-- Verificación rápida (como service role / en SQL editor):
-- SELECT public.caipi_puede_ver_todos_alumnos();  -- con sesión de directora → true
