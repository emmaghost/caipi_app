-- ============================================
-- FIX: Políticas RLS para permitir operaciones
-- ============================================
-- Este script agrega políticas permisivas para que la directora
-- pueda crear y modificar registros en todas las tablas

-- ============================================
-- 1. PROFESORES
-- ============================================
DROP POLICY IF EXISTS "Directora puede insertar profesores" ON public.profesores;
CREATE POLICY "Directora puede insertar profesores"
ON public.profesores
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol = 'directora'
  )
);

DROP POLICY IF EXISTS "Directora puede actualizar profesores" ON public.profesores;
CREATE POLICY "Directora puede actualizar profesores"
ON public.profesores
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol = 'directora'
  )
);

-- ============================================
-- 2. BITÁCORA DIARIA
-- ============================================
DROP POLICY IF EXISTS "Profesores y directora pueden insertar bitácoras" ON public.bitacora_diaria;
CREATE POLICY "Profesores y directora pueden insertar bitácoras"
ON public.bitacora_diaria
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

DROP POLICY IF EXISTS "Profesores y directora pueden actualizar sus bitácoras" ON public.bitacora_diaria;
CREATE POLICY "Profesores y directora pueden actualizar sus bitácoras"
ON public.bitacora_diaria
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

-- ============================================
-- 3. ANUNCIOS
-- ============================================
DROP POLICY IF EXISTS "Directora puede insertar anuncios" ON public.anuncios;
CREATE POLICY "Directora puede insertar anuncios"
ON public.anuncios
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor_admin')
  )
);

DROP POLICY IF EXISTS "Directora puede actualizar anuncios" ON public.anuncios;
CREATE POLICY "Directora puede actualizar anuncios"
ON public.anuncios
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor_admin')
  )
);

-- ============================================
-- 4. EVENTOS
-- ============================================
DROP POLICY IF EXISTS "Directora puede insertar eventos" ON public.eventos;
CREATE POLICY "Directora puede insertar eventos"
ON public.eventos
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor_admin')
  )
);

DROP POLICY IF EXISTS "Directora puede actualizar eventos" ON public.eventos;
CREATE POLICY "Directora puede actualizar eventos"
ON public.eventos
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor_admin')
  )
);

-- ============================================
-- 5. INCIDENTES
-- ============================================
DROP POLICY IF EXISTS "Profesores y directora pueden insertar incidentes" ON public.incidentes;
CREATE POLICY "Profesores y directora pueden insertar incidentes"
ON public.incidentes
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

DROP POLICY IF EXISTS "Profesores y directora pueden actualizar incidentes" ON public.incidentes;
CREATE POLICY "Profesores y directora pueden actualizar incidentes"
ON public.incidentes
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

-- ============================================
-- 6. TIPOS DE INCIDENTES
-- ============================================
DROP POLICY IF EXISTS "Directora puede insertar tipos de incidentes" ON public.tipos_incidentes;
CREATE POLICY "Directora puede insertar tipos de incidentes"
ON public.tipos_incidentes
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol = 'directora'
  )
);

DROP POLICY IF EXISTS "Directora puede actualizar tipos de incidentes" ON public.tipos_incidentes;
CREATE POLICY "Directora puede actualizar tipos de incidentes"
ON public.tipos_incidentes
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol = 'directora'
  )
);

-- ============================================
-- 7. PAGOS
-- ============================================
DROP POLICY IF EXISTS "Directora puede actualizar pagos" ON public.pagos;
CREATE POLICY "Directora puede actualizar pagos"
ON public.pagos
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol = 'directora'
  )
);

-- ============================================
-- 8. CONTROL DE SALIDAS
-- ============================================
DROP POLICY IF EXISTS "Profesores y directora pueden insertar control salidas" ON public.control_salidas;
CREATE POLICY "Profesores y directora pueden insertar control salidas"
ON public.control_salidas
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

DROP POLICY IF EXISTS "Profesores y directora pueden actualizar control salidas" ON public.control_salidas;
CREATE POLICY "Profesores y directora pueden actualizar control salidas"
ON public.control_salidas
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

DROP POLICY IF EXISTS "Profesores y directora pueden leer control salidas" ON public.control_salidas;
CREATE POLICY "Profesores y directora pueden leer control salidas"
ON public.control_salidas
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
    AND rol IN ('directora', 'profesor', 'profesor_admin')
  )
);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Ver todas las políticas creadas
SELECT schemaname, tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('profesores', 'bitacora_diaria', 'anuncios', 'eventos', 'incidentes', 'tipos_incidentes', 'pagos', 'control_salidas')
ORDER BY tablename, policyname;
