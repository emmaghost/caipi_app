-- =====================================================
-- FIX URGENTE: RLS POLICIES PARA ALUMNOS
-- =====================================================
-- Este script corrige las políticas de seguridad que están
-- bloqueando la creación de alumnos

-- 1. ELIMINAR políticas antiguas que causan conflicto
DROP POLICY IF EXISTS "Padres ven solo sus hijos" ON alumnos;
DROP POLICY IF EXISTS "Directora gestiona alumnos" ON alumnos;
DROP POLICY IF EXISTS "Directora puede gestionar alumnos" ON alumnos;
DROP POLICY IF EXISTS "Todos pueden ver alumnos" ON alumnos;

-- 2. CREAR política permisiva para SELECT (ver alumnos)
CREATE POLICY "Ver alumnos"
ON alumnos FOR SELECT
TO authenticated
USING (
    -- Directora y profesor_admin ven todos
    EXISTS (
        SELECT 1 FROM usuarios
        WHERE id = auth.uid() 
        AND rol IN ('directora', 'profesor_admin', 'profesor')
    )
    OR
    -- Padres solo ven sus hijos
    padre_id = auth.uid()
);

-- 3. CREAR política permisiva para INSERT (crear alumnos)
CREATE POLICY "Crear alumnos"
ON alumnos FOR INSERT
TO authenticated
WITH CHECK (
    -- Solo directora y profesor_admin pueden crear
    EXISTS (
        SELECT 1 FROM usuarios
        WHERE id = auth.uid() 
        AND rol IN ('directora', 'profesor_admin')
    )
);

-- 4. CREAR política permisiva para UPDATE (editar alumnos)
CREATE POLICY "Editar alumnos"
ON alumnos FOR UPDATE
TO authenticated
USING (
    -- Solo directora y profesor_admin pueden editar
    EXISTS (
        SELECT 1 FROM usuarios
        WHERE id = auth.uid() 
        AND rol IN ('directora', 'profesor_admin')
    )
);

-- 5. CREAR política permisiva para DELETE (eliminar alumnos)
CREATE POLICY "Eliminar alumnos"
ON alumnos FOR DELETE
TO authenticated
USING (
    -- Solo directora puede eliminar
    EXISTS (
        SELECT 1 FROM usuarios
        WHERE id = auth.uid() 
        AND rol = 'directora'
    )
);

-- 6. VERIFICAR que las políticas se crearon correctamente
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'alumnos'
ORDER BY policyname;

-- =====================================================
-- ✅ SCRIPT COMPLETADO
-- =====================================================
-- Ahora intenta crear el alumno de nuevo
