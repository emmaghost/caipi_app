-- ============================================================
-- Caja: ver alumnos + gestionar pagos/abonos
-- Sin esto, joss@caipi.com ve 0 alumnos → la app oculta TODOS
-- los cargos (filtra por IDs de alumnos vacíos).
-- Ejecutar en Supabase → SQL Editor → Run
-- ============================================================

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

-- Lectura de alumnos para cobros y staff escolar
CREATE OR REPLACE FUNCTION public.caipi_puede_ver_alumnos_cobros()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.rol IN ('directora', 'profesor_admin', 'secretaria', 'caja')
      AND COALESCE(u.activo, true) = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_puede_ver_alumnos_cobros() TO authenticated;

DROP POLICY IF EXISTS "alumnos_select" ON public.alumnos;
DROP POLICY IF EXISTS "Ver alumnos" ON public.alumnos;

CREATE POLICY "alumnos_select" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    public.caipi_puede_ver_alumnos_cobros()
    OR public.usuario_gestiona_pagos()
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
        AND p.activo = true
        AND alumnos.grado_id IN (
          SELECT g FROM public.grados_de_profesor(auth.uid()) AS g
        )
    )
  );

-- Grados: lectura para todos autenticados
DROP POLICY IF EXISTS "Ver grados" ON public.grados;
CREATE POLICY "Ver grados" ON public.grados
  FOR SELECT TO authenticated
  USING (true);

-- Pagos / abonos: directora + caja
DROP POLICY IF EXISTS "Directora gestiona pagos" ON public.pagos;
DROP POLICY IF EXISTS "Staff gestiona pagos" ON public.pagos;
CREATE POLICY "Staff gestiona pagos"
  ON public.pagos FOR ALL TO authenticated
  USING (public.usuario_gestiona_pagos())
  WITH CHECK (public.usuario_gestiona_pagos());

DROP POLICY IF EXISTS "Directora gestiona abonos" ON public.abonos;
DROP POLICY IF EXISTS "Staff gestiona abonos" ON public.abonos;
CREATE POLICY "Staff gestiona abonos"
  ON public.abonos FOR ALL TO authenticated
  USING (public.usuario_gestiona_pagos())
  WITH CHECK (public.usuario_gestiona_pagos());

SELECT
  (SELECT COUNT(*) FROM public.usuarios WHERE email ILIKE 'joss@caipi.com' AND rol = 'caja') AS caja_ok;

NOTIFY pgrst, 'reload schema';
