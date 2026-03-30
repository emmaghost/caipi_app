-- =====================================================
-- FORMULARIO DE ENTREVISTA A PADRES (PRE-INSCRIPCIÓN)
-- =====================================================

-- 1. CREAR tabla entrevistas_padres
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
    vive_tipo VARCHAR(50), -- 'Casa', 'Departamento', 'Otro'
    vive_condicion VARCHAR(50), -- 'Propia', 'Rentada', 'De un familiar'
    
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
    embarazo_planeado VARCHAR(50), -- 'Sí', 'No'
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
    se_ata_cordones_sola BOOLEAN,
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

-- 2. ÍNDICES para búsqueda rápida
CREATE INDEX IF NOT EXISTS idx_entrevistas_alumno ON entrevistas_padres(alumno_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_padre ON entrevistas_padres(padre_usuario_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_completado ON entrevistas_padres(completado);

-- 3. TRIGGER para actualizar updated_at
CREATE OR REPLACE FUNCTION actualizar_entrevista_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_entrevista_updated_at
    BEFORE UPDATE ON entrevistas_padres
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_entrevista_updated_at();

-- 4. RLS POLICIES
ALTER TABLE entrevistas_padres ENABLE ROW LEVEL SECURITY;

-- Policy: Directora puede ver todas las entrevistas
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

-- Policy: Directora puede crear entrevistas
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

-- Policy: Directora puede actualizar entrevistas
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

-- Policy: Padres pueden ver su propia entrevista
CREATE POLICY "Padres pueden ver su propia entrevista"
ON entrevistas_padres FOR SELECT
TO authenticated
USING (
    padre_usuario_id = auth.uid()
);

-- 5. AGREGAR PERMISO
INSERT INTO permisos (codigo, nombre, descripcion, categoria)
VALUES 
    ('gestionar_entrevistas', 'Gestionar Entrevistas', 'Crear y editar entrevistas de padres', 'admin')
ON CONFLICT (codigo) DO NOTHING;

-- Asignar permiso al rol directora
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM roles r, permisos p
WHERE r.nombre = 'Directora' AND p.codigo = 'gestionar_entrevistas'
ON CONFLICT DO NOTHING;

-- 6. COMENTARIOS para documentación
COMMENT ON TABLE entrevistas_padres IS 'Formulario de entrevista a padres previo a inscripción';
COMMENT ON COLUMN entrevistas_padres.alumno_id IS 'Alumno al que pertenece la entrevista';
COMMENT ON COLUMN entrevistas_padres.padre_usuario_id IS 'Usuario padre que respondió la entrevista';
COMMENT ON COLUMN entrevistas_padres.completado IS 'Indica si la entrevista fue completada';

-- 7. VERIFICAR estructura
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'entrevistas_padres'
ORDER BY ordinal_position;
