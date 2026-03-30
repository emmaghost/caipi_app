-- =====================================================
-- SQL MAESTRO - EJECUTAR TODO DE UNA VEZ
-- =====================================================
-- Este script combina TODOS los fixes necesarios
-- Ejecuta esto en Supabase y se corrige todo

-- =====================================================
-- 1. FIX PAGOS EXISTENTES
-- =====================================================

-- Agregar fecha_vencimiento a pagos que no la tienen
UPDATE pagos
SET fecha_vencimiento = (created_at + interval '30 days')::date
WHERE fecha_vencimiento IS NULL;

-- Eliminar pagos duplicados (solo mantener el más reciente)
DELETE FROM pagos p1
WHERE EXISTS (
    SELECT 1 FROM pagos p2
    WHERE p2.alumno_id = p1.alumno_id 
    AND p2.concepto = p1.concepto
    AND p2.created_at > p1.created_at
);

-- =====================================================
-- 2. AGREGAR CAMPOS A ALUMNOS
-- =====================================================

-- Dirección
ALTER TABLE alumnos
ADD COLUMN IF NOT EXISTS calle VARCHAR(200),
ADD COLUMN IF NOT EXISTS colonia VARCHAR(100),
ADD COLUMN IF NOT EXISTS codigo_postal VARCHAR(10),
ADD COLUMN IF NOT EXISTS ciudad VARCHAR(100) DEFAULT 'Iztapalapa',
ADD COLUMN IF NOT EXISTS estado VARCHAR(100) DEFAULT 'CDMX';

-- CURP
ALTER TABLE alumnos
ADD COLUMN IF NOT EXISTS curp VARCHAR(18) UNIQUE;

-- Cartilla de vacunas
ALTER TABLE alumnos
ADD COLUMN IF NOT EXISTS cartilla_completa BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS vacunas_faltantes TEXT;

-- Índice para CURP
CREATE INDEX IF NOT EXISTS idx_alumnos_curp ON alumnos(curp);

-- =====================================================
-- 3. CORREGIR GRADOS (SOLO MATERNAL Y KINDER 1,2,3)
-- =====================================================

-- Primero: Desactivar grados incorrectos (por si hay alumnos asignados)
UPDATE grados 
SET activo = false 
WHERE nombre NOT IN ('Maternal', 'Kinder 1', 'Kinder 2', 'Kinder 3');

-- Segundo: Intentar eliminar grados incorrectos (solo si no tienen alumnos)
DELETE FROM grados 
WHERE nombre NOT IN ('Maternal', 'Kinder 1', 'Kinder 2', 'Kinder 3')
AND NOT EXISTS (
    SELECT 1 FROM alumnos WHERE grado_id = grados.id
);

-- Tercero: Insertar/actualizar grados correctos
-- Usamos un DO block para manejar si ya existen
DO $$
DECLARE
    maternal_exists BOOLEAN;
    kinder1_exists BOOLEAN;
    kinder2_exists BOOLEAN;
    kinder3_exists BOOLEAN;
BEGIN
    -- Verificar si existen
    SELECT EXISTS(SELECT 1 FROM grados WHERE nombre = 'Maternal') INTO maternal_exists;
    SELECT EXISTS(SELECT 1 FROM grados WHERE nombre = 'Kinder 1') INTO kinder1_exists;
    SELECT EXISTS(SELECT 1 FROM grados WHERE nombre = 'Kinder 2') INTO kinder2_exists;
    SELECT EXISTS(SELECT 1 FROM grados WHERE nombre = 'Kinder 3') INTO kinder3_exists;
    
    -- Insertar o actualizar cada grado
    IF maternal_exists THEN
        UPDATE grados SET 
            descripcion = 'Nivel Maternal',
            edad_minima = 0,
            edad_maxima = 3,
            cupo_maximo = 20,
            activo = true,
            updated_at = now()
        WHERE nombre = 'Maternal';
    ELSE
        INSERT INTO grados (nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
        VALUES ('Maternal', 'Nivel Maternal', 0, 3, 20, true, now(), now());
    END IF;
    
    IF kinder1_exists THEN
        UPDATE grados SET 
            descripcion = 'Primer año de Kinder',
            edad_minima = 3,
            edad_maxima = 4,
            cupo_maximo = 25,
            activo = true,
            updated_at = now()
        WHERE nombre = 'Kinder 1';
    ELSE
        INSERT INTO grados (nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
        VALUES ('Kinder 1', 'Primer año de Kinder', 3, 4, 25, true, now(), now());
    END IF;
    
    IF kinder2_exists THEN
        UPDATE grados SET 
            descripcion = 'Segundo año de Kinder',
            edad_minima = 4,
            edad_maxima = 5,
            cupo_maximo = 25,
            activo = true,
            updated_at = now()
        WHERE nombre = 'Kinder 2';
    ELSE
        INSERT INTO grados (nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
        VALUES ('Kinder 2', 'Segundo año de Kinder', 4, 5, 25, true, now(), now());
    END IF;
    
    IF kinder3_exists THEN
        UPDATE grados SET 
            descripcion = 'Tercer año de Kinder',
            edad_minima = 5,
            edad_maxima = 6,
            cupo_maximo = 25,
            activo = true,
            updated_at = now()
        WHERE nombre = 'Kinder 3';
    ELSE
        INSERT INTO grados (nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
        VALUES ('Kinder 3', 'Tercer año de Kinder', 5, 6, 25, true, now(), now());
    END IF;
END $$;

-- =====================================================
-- 4. CREAR TABLA ENTREVISTAS PADRES
-- =====================================================

CREATE TABLE IF NOT EXISTS entrevistas_padres (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alumno_id UUID REFERENCES alumnos(id) ON DELETE CASCADE,
    padre_usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    
    -- SECCIÓN 1: DATOS DE LA MADRE
    madre_nombre VARCHAR(200),
    madre_edad INTEGER,
    madre_ocupacion VARCHAR(200),
    madre_direccion VARCHAR(300),
    madre_grado_estudios VARCHAR(100),
    madre_telefono VARCHAR(20),
    
    -- SECCIÓN 2: DATOS DEL PADRE
    padre_nombre VARCHAR(200),
    padre_edad INTEGER,
    padre_ocupacion VARCHAR(200),
    padre_direccion VARCHAR(300),
    padre_grado_estudios VARCHAR(100),
    padre_telefono VARCHAR(20),
    
    -- SECCIÓN 3: DIRECCIÓN DONDE VIVE EL ALUMNO
    vive_calle VARCHAR(200),
    vive_colonia VARCHAR(100),
    vive_numero VARCHAR(20),
    vive_referencia TEXT,
    vive_tipo VARCHAR(50),
    vive_condicion VARCHAR(50),
    
    -- SECCIÓN 4: INFORMACIÓN DEL HOGAR
    personas_viven_con TEXT,
    quien_cuida_cuando_no_escuela TEXT,
    enfermedades_padecimientos TEXT,
    alergias_cuidados TEXT,
    control_esfinteres BOOLEAN,
    control_esfinteres_edad VARCHAR(50),
    necesidades_educativas_especiales TEXT,
    dificultades_realizar TEXT,
    motivo_inasistencias TEXT,
    
    -- SECCIÓN 5: ANTECEDENTES
    embarazo_planeado VARCHAR(50),
    tiempo_embarazo VARCHAR(50),
    dificultades_embarazo TEXT,
    edad_camino VARCHAR(50),
    edad_hablo VARCHAR(50),
    
    -- SECCIÓN 6: PADRES SEPARADOS
    padres_separados BOOLEAN DEFAULT false,
    quien_patria_potestad VARCHAR(200),
    convive_otra_parte TEXT,
    tiene_padrastro_madrastra TEXT,
    relacion_padrastro_madrastra TEXT,
    como_se_refiere_a_el TEXT,
    tiene_hermanastros TEXT,
    relacion_hermanastros TEXT,
    
    -- SECCIÓN 7: ASPECTO SOCIAL DEL HIJO
    caracter_hijo TEXT,
    que_la_hace_enojar TEXT,
    que_la_pone_triste TEXT,
    como_actua_cuando_asi TEXT,
    que_mas_le_gusta_hacer TEXT,
    se_viste_sola BOOLEAN,
    se_ata_cordones_sola VARCHAR(100),
    habitos_higiene TEXT,
    rutina_despues_escuela TEXT,
    hora_duerme VARCHAR(50),
    hora_despierta VARCHAR(50),
    
    -- SECCIÓN 8: ASPECTO SOCIAL (FAMILIA)
    sale_fines_semana BOOLEAN,
    sale_a_donde TEXT,
    actividades_familia TEXT,
    hace_amigos_facilidad BOOLEAN,
    nombres_amigos TEXT,
    tiene_mascotas BOOLEAN,
    mascotas_cuales TEXT,
    ayuda_quehaceres BOOLEAN,
    cuando_porta_mal_actua TEXT,
    hay_castigos_cuales TEXT,
    cuando_porta_bien_actua TEXT,
    dicen_grocerias_quien TEXT,
    juguetes_usa_frecuencia TEXT,
    
    -- SECCIÓN 9: SOBRE NOSOTROS (EXPECTATIVAS)
    que_espera_maestra TEXT,
    que_espera_escuela TEXT,
    dispuesto_apoyar_escuela BOOLEAN,
    
    -- Metadatos
    completado BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_by UUID REFERENCES usuarios(id)
);

-- Índices para entrevistas
CREATE INDEX IF NOT EXISTS idx_entrevistas_alumno ON entrevistas_padres(alumno_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_padre ON entrevistas_padres(padre_usuario_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_completado ON entrevistas_padres(completado);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION actualizar_entrevista_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_actualizar_entrevista_updated_at ON entrevistas_padres;
CREATE TRIGGER trigger_actualizar_entrevista_updated_at
    BEFORE UPDATE ON entrevistas_padres
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_entrevista_updated_at();

-- RLS para entrevistas_padres
ALTER TABLE entrevistas_padres ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Directora puede ver todas las entrevistas" ON entrevistas_padres;
CREATE POLICY "Directora puede ver todas las entrevistas"
ON entrevistas_padres FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = auth.uid()
        AND u.rol = 'directora'
    )
);

DROP POLICY IF EXISTS "Directora puede crear entrevistas" ON entrevistas_padres;
CREATE POLICY "Directora puede crear entrevistas"
ON entrevistas_padres FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = auth.uid()
        AND u.rol = 'directora'
    )
);

DROP POLICY IF EXISTS "Directora puede actualizar entrevistas" ON entrevistas_padres;
CREATE POLICY "Directora puede actualizar entrevistas"
ON entrevistas_padres FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = auth.uid()
        AND u.rol = 'directora'
    )
);

DROP POLICY IF EXISTS "Padres pueden ver su propia entrevista" ON entrevistas_padres;
CREATE POLICY "Padres pueden ver su propia entrevista"
ON entrevistas_padres FOR SELECT
TO authenticated
USING (
    padre_usuario_id = auth.uid()
);

-- Agregar permiso
INSERT INTO permisos (clave, nombre, descripcion, modulo)
VALUES 
    ('gestionar_entrevistas', 'Gestionar Entrevistas', 'Crear y editar entrevistas de padres', 'admin')
ON CONFLICT (clave) DO NOTHING;

-- Asignar permiso al rol directora
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM roles r, permisos p
WHERE r.codigo = 'directora' AND p.clave = 'gestionar_entrevistas'
ON CONFLICT DO NOTHING;

-- =====================================================
-- 5. VERIFICACIÓN FINAL
-- =====================================================

-- Verificar grados correctos
SELECT 
    '✅ GRADOS CORRECTOS' as status,
    nombre,
    descripcion,
    edad_minima,
    edad_maxima
FROM grados
WHERE activo = true
ORDER BY 
    CASE 
        WHEN nombre = 'Maternal' THEN 1
        WHEN nombre = 'Kinder 1' THEN 2
        WHEN nombre = 'Kinder 2' THEN 3
        WHEN nombre = 'Kinder 3' THEN 4
    END;

-- Verificar pagos corregidos
SELECT 
    '✅ PAGOS CORREGIDOS' as status,
    COUNT(*) as total_pagos,
    COUNT(CASE WHEN fecha_vencimiento IS NULL THEN 1 END) as sin_fecha_vencimiento
FROM pagos;

-- Verificar tabla entrevistas
SELECT 
    '✅ TABLA ENTREVISTAS CREADA' as status,
    COUNT(*) as total_entrevistas
FROM entrevistas_padres;

-- =====================================================
-- ✅ SCRIPT COMPLETADO
-- =====================================================
-- Si ves este mensaje, todo se ejecutó correctamente.
-- Ahora:
-- 1. Cierra sesión en la app
-- 2. Inicia sesión de nuevo
-- 3. Verifica que aparecen solo: Maternal, Kinder 1, Kinder 2, Kinder 3
-- 4. Verifica que Pagos funciona sin errores
-- 5. Verifica que aparece "Entrevista a Padres" en el menú
