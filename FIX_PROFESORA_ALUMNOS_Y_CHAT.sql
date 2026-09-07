-- =============================================================================
-- HOTFIX: recursión infinita en usuarios_select (error 42P17)
-- Ejecutar YA en Supabase → SQL Editor → Run
--
-- Causa: la policy de usuarios hacía EXISTS sobre usuarios → loop.
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

CREATE OR REPLACE FUNCTION public.caipi_es_staff_escuela()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.caipi_rol_actual() IN (
    'directora', 'profesor', 'profesor_admin', 'secretaria', 'caja'
  );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_es_staff_escuela() TO authenticated;

CREATE OR REPLACE FUNCTION public.caipi_es_directora_o_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.caipi_rol_actual() IN ('directora', 'profesor_admin');
$$;

GRANT EXECUTE ON FUNCTION public.caipi_es_directora_o_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.caipi_puede_alta_alumnos()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.caipi_rol_actual() IN ('directora', 'profesor_admin', 'secretaria');
$$;

GRANT EXECUTE ON FUNCTION public.caipi_puede_alta_alumnos() TO authenticated;

CREATE OR REPLACE FUNCTION public.usuario_gestiona_pagos(p_uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = p_uid
      AND u.rol IN ('directora', 'caja')
      AND COALESCE(u.activo, true) = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.usuario_gestiona_pagos(UUID) TO authenticated;

-- Multi-grupo helper (por si falta)
CREATE TABLE IF NOT EXISTS public.profesores_grados (
  profesor_id UUID NOT NULL REFERENCES public.profesores(id) ON DELETE CASCADE,
  grado_id UUID NOT NULL REFERENCES public.grados(id) ON DELETE CASCADE,
  PRIMARY KEY (profesor_id, grado_id)
);

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

INSERT INTO public.profesores_grados (profesor_id, grado_id)
SELECT p.id, p.grado_id
FROM public.profesores p
WHERE p.grado_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- ---- USUARIOS: sin auto-consulta en la policy ----
DROP POLICY IF EXISTS "usuarios_select" ON public.usuarios;
DROP POLICY IF EXISTS "Ver usuarios" ON public.usuarios;

CREATE POLICY "usuarios_select" ON public.usuarios
  FOR SELECT TO authenticated
  USING (
    auth.uid() = id
    OR public.caipi_es_directora_o_admin()
    OR (
      public.caipi_es_staff_escuela()
      AND rol = 'padre'
    )
    OR (
      public.caipi_rol_actual() = 'padre'
      AND rol IN ('directora', 'profesor', 'profesor_admin')
      AND COALESCE(activo, true) = true
    )
    OR (
      public.caipi_es_staff_escuela()
      AND rol IN ('directora', 'profesor', 'profesor_admin', 'secretaria', 'caja')
    )
  );

-- ---- ALUMNOS: usa helpers, no EXISTS crudo sobre usuarios ----
DROP POLICY IF EXISTS "alumnos_select" ON public.alumnos;
DROP POLICY IF EXISTS "Ver alumnos" ON public.alumnos;

CREATE POLICY "alumnos_select" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    public.usuario_gestiona_pagos()
    OR public.caipi_puede_alta_alumnos()
    OR public.caipi_rol_actual() = 'profesor_admin'
    OR padre_id = auth.uid()
    OR (
      to_regclass('public.alumnos_padres') IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.alumnos_padres ap
        WHERE ap.alumno_id = alumnos.id AND ap.padre_id = auth.uid()
      )
    )
    OR (
      public.caipi_rol_actual() = 'profesor'
      AND alumnos.grado_id IN (
        SELECT public.grados_de_profesor(auth.uid())
      )
    )
  );

NOTIFY pgrst, 'reload schema';
