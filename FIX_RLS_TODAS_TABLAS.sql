-- =====================================================
-- FIX COMPLETO: RLS PARA TODAS LAS TABLAS
-- =====================================================

-- =====================================================
-- 1. ALUMNOS
-- =====================================================
DROP POLICY IF EXISTS "Padres ven solo sus hijos" ON alumnos;
DROP POLICY IF EXISTS "Directora gestiona alumnos" ON alumnos;
DROP POLICY IF EXISTS "Ver alumnos" ON alumnos;
DROP POLICY IF EXISTS "Crear alumnos" ON alumnos;
DROP POLICY IF EXISTS "Editar alumnos" ON alumnos;
DROP POLICY IF EXISTS "Eliminar alumnos" ON alumnos;

CREATE POLICY "Ver alumnos" ON alumnos FOR SELECT TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin', 'profesor'))
    OR padre_id = auth.uid()
);

CREATE POLICY "Crear alumnos" ON alumnos FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

CREATE POLICY "Editar alumnos" ON alumnos FOR UPDATE TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

CREATE POLICY "Eliminar alumnos" ON alumnos FOR DELETE TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- =====================================================
-- 2. PAGOS
-- =====================================================
DROP POLICY IF EXISTS "Padres ven pagos de sus hijos" ON pagos;
DROP POLICY IF EXISTS "Directora gestiona pagos" ON pagos;
DROP POLICY IF EXISTS "Ver pagos" ON pagos;
DROP POLICY IF EXISTS "Crear pagos" ON pagos;
DROP POLICY IF EXISTS "Editar pagos" ON pagos;

CREATE POLICY "Ver pagos" ON pagos FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM alumnos 
        WHERE id = pagos.alumno_id 
        AND (padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
        ))
    )
);

CREATE POLICY "Crear pagos" ON pagos FOR INSERT TO authenticated
WITH CHECK (true); -- Permitir creación (el trigger los crea automáticamente)

CREATE POLICY "Editar pagos" ON pagos FOR UPDATE TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 3. PROFESORES
-- =====================================================
DROP POLICY IF EXISTS "Todos pueden ver profesores" ON profesores;
DROP POLICY IF EXISTS "Directora puede gestionar profesores" ON profesores;
DROP POLICY IF EXISTS "Ver profesores" ON profesores;
DROP POLICY IF EXISTS "Gestionar profesores" ON profesores;

CREATE POLICY "Ver profesores" ON profesores FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Gestionar profesores" ON profesores FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 4. USUARIOS (tabla principal)
-- =====================================================
DROP POLICY IF EXISTS "Permitir lectura autenticados" ON usuarios;
DROP POLICY IF EXISTS "Permitir escritura autenticados" ON usuarios;
DROP POLICY IF EXISTS "Ver usuarios" ON usuarios;
DROP POLICY IF EXISTS "Gestionar usuarios" ON usuarios;
DROP POLICY IF EXISTS "Crear usuarios" ON usuarios;
DROP POLICY IF EXISTS "Editar usuarios" ON usuarios;
DROP POLICY IF EXISTS "Eliminar usuarios" ON usuarios;

CREATE POLICY "Ver usuarios" ON usuarios FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Crear usuarios" ON usuarios FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
    OR auth.uid() = id -- Permitir que un usuario se cree a sí mismo
);

CREATE POLICY "Editar usuarios" ON usuarios FOR UPDATE TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
    OR auth.uid() = id -- Permitir que un usuario se edite a sí mismo
);

-- =====================================================
-- 5. GRADOS
-- =====================================================
DROP POLICY IF EXISTS "Todos pueden ver grados" ON grados;
DROP POLICY IF EXISTS "Directora puede gestionar grados" ON grados;
DROP POLICY IF EXISTS "Ver grados" ON grados;
DROP POLICY IF EXISTS "Gestionar grados" ON grados;

CREATE POLICY "Ver grados" ON grados FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Gestionar grados" ON grados FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 6. EVENTOS
-- =====================================================
DROP POLICY IF EXISTS "Ver eventos activos" ON eventos;
DROP POLICY IF EXISTS "Gestionar eventos" ON eventos;
DROP POLICY IF EXISTS "Ver eventos" ON eventos;

CREATE POLICY "Ver eventos" ON eventos FOR SELECT TO authenticated
USING (activo = true);

CREATE POLICY "Gestionar eventos" ON eventos FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 7. INCIDENTES
-- =====================================================
DROP POLICY IF EXISTS "Ver incidentes" ON incidentes;
DROP POLICY IF EXISTS "Crear/modificar incidentes" ON incidentes;
DROP POLICY IF EXISTS "Gestionar incidentes" ON incidentes;

CREATE POLICY "Ver incidentes" ON incidentes FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM alumnos a
        WHERE a.id = incidentes.alumno_id
        AND (a.padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin', 'profesor')
        ))
    )
);

CREATE POLICY "Gestionar incidentes" ON incidentes FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin', 'profesor'))
);

-- =====================================================
-- 8. TIPOS DE INCIDENTES
-- =====================================================
DROP POLICY IF EXISTS "Ver tipos incidentes" ON tipos_incidentes;
DROP POLICY IF EXISTS "Gestionar tipos incidentes" ON tipos_incidentes;

CREATE POLICY "Ver tipos incidentes" ON tipos_incidentes FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Gestionar tipos incidentes" ON tipos_incidentes FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 9. ANUNCIOS
-- =====================================================
DROP POLICY IF EXISTS "Todos pueden ver anuncios" ON anuncios;
DROP POLICY IF EXISTS "Directora gestiona anuncios" ON anuncios;
DROP POLICY IF EXISTS "Ver anuncios" ON anuncios;
DROP POLICY IF EXISTS "Gestionar anuncios" ON anuncios;

CREATE POLICY "Ver anuncios" ON anuncios FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Gestionar anuncios" ON anuncios FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 10. BITÁCORA DIARIA
-- =====================================================
DROP POLICY IF EXISTS "Ver bitacora" ON bitacora_diaria;
DROP POLICY IF EXISTS "Gestionar bitacora" ON bitacora_diaria;

CREATE POLICY "Ver bitacora" ON bitacora_diaria FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM alumnos a
        WHERE a.id = bitacora_diaria.alumno_id
        AND (a.padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin', 'profesor')
        ))
    )
);

CREATE POLICY "Gestionar bitacora" ON bitacora_diaria FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin', 'profesor'))
);

-- =====================================================
-- 11. CONTROL SALIDAS
-- =====================================================
DROP POLICY IF EXISTS "Ver salidas" ON control_salidas;
DROP POLICY IF EXISTS "Gestionar salidas" ON control_salidas;

CREATE POLICY "Ver salidas" ON control_salidas FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM alumnos a
        WHERE a.id = control_salidas.alumno_id
        AND (a.padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin', 'profesor')
        ))
    )
);

CREATE POLICY "Gestionar salidas" ON control_salidas FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin', 'profesor'))
);

-- =====================================================
-- 12. PERSONAS AUTORIZADAS
-- =====================================================
DROP POLICY IF EXISTS "Ver personas autorizadas" ON personas_autorizadas;
DROP POLICY IF EXISTS "Padres gestionan personas autorizadas" ON personas_autorizadas;
DROP POLICY IF EXISTS "Gestionar personas autorizadas" ON personas_autorizadas;

CREATE POLICY "Ver personas autorizadas" ON personas_autorizadas FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM alumnos a
        WHERE a.id = personas_autorizadas.alumno_id
        AND (a.padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin', 'profesor')
        ))
    )
);

CREATE POLICY "Gestionar personas autorizadas" ON personas_autorizadas FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM alumnos a
        WHERE a.id = personas_autorizadas.alumno_id
        AND (a.padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin')
        ))
    )
);

-- =====================================================
-- 13. ENTREVISTAS PADRES (NUEVA)
-- =====================================================
DROP POLICY IF EXISTS "Directora puede ver todas las entrevistas" ON entrevistas_padres;
DROP POLICY IF EXISTS "Directora puede crear entrevistas" ON entrevistas_padres;
DROP POLICY IF EXISTS "Directora puede actualizar entrevistas" ON entrevistas_padres;
DROP POLICY IF EXISTS "Padres pueden ver su propia entrevista" ON entrevistas_padres;
DROP POLICY IF EXISTS "Ver entrevistas" ON entrevistas_padres;
DROP POLICY IF EXISTS "Gestionar entrevistas" ON entrevistas_padres;

CREATE POLICY "Ver entrevistas" ON entrevistas_padres FOR SELECT TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
    OR padre_usuario_id = auth.uid()
);

CREATE POLICY "Gestionar entrevistas" ON entrevistas_padres FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 14. ABONOS (Pagos Parciales)
-- =====================================================
DROP POLICY IF EXISTS "Directora puede ver abonos" ON abonos;
DROP POLICY IF EXISTS "Directora puede insertar abonos" ON abonos;
DROP POLICY IF EXISTS "Padres pueden ver sus abonos" ON abonos;
DROP POLICY IF EXISTS "Ver abonos" ON abonos;
DROP POLICY IF EXISTS "Gestionar abonos" ON abonos;

CREATE POLICY "Ver abonos" ON abonos FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM pagos p
        INNER JOIN alumnos a ON p.alumno_id = a.id
        WHERE p.id = abonos.pago_id
        AND (a.padre_id = auth.uid() OR EXISTS (
            SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin')
        ))
    )
);

CREATE POLICY "Gestionar abonos" ON abonos FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

-- =====================================================
-- 15. CONFIGURACIÓN COSTOS
-- =====================================================
DROP POLICY IF EXISTS "Directora puede gestionar configuracion_costos" ON configuracion_costos;
DROP POLICY IF EXISTS "Directora puede ver configuracion_costos" ON configuracion_costos;
DROP POLICY IF EXISTS "Ver configuracion" ON configuracion_costos;
DROP POLICY IF EXISTS "Gestionar configuracion" ON configuracion_costos;

CREATE POLICY "Ver configuracion" ON configuracion_costos FOR SELECT TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin'))
);

CREATE POLICY "Gestionar configuracion" ON configuracion_costos FOR ALL TO authenticated
USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- =====================================================
-- ✅ VERIFICACIÓN FINAL
-- =====================================================
SELECT 
    '✅ POLÍTICAS RLS CORREGIDAS' as status,
    tablename,
    COUNT(*) as total_policies
FROM pg_policies
WHERE tablename IN ('alumnos', 'pagos', 'profesores', 'usuarios', 'grados', 'eventos', 'incidentes', 'entrevistas_padres', 'abonos', 'configuracion_costos')
GROUP BY tablename
ORDER BY tablename;

-- =====================================================
-- ✅ SCRIPT COMPLETADO
-- =====================================================
