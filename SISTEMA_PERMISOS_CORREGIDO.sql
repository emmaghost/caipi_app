-- ============================================
-- SISTEMA DE PERMISOS - CAIPI (CORREGIDO)
-- ============================================

-- ============================================
-- 1. TABLA DE PERMISOS (CATÁLOGO)
-- ============================================
CREATE TABLE IF NOT EXISTS permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT NOT NULL UNIQUE, -- 'ver_alumnos', 'crear_alumno', 'ver_pagos', etc.
  nombre TEXT NOT NULL,
  descripcion TEXT,
  modulo TEXT NOT NULL, -- 'alumnos', 'pagos', 'profesores', 'eventos', etc.
  tipo TEXT NOT NULL CHECK (tipo IN ('lectura', 'escritura', 'eliminacion', 'especial')),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_permisos_codigo ON permisos(codigo);
CREATE INDEX IF NOT EXISTS idx_permisos_modulo ON permisos(modulo);

-- ============================================
-- 2. TABLA DE ROLES (ACTUALIZADA)
-- ============================================
CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT NOT NULL UNIQUE, -- 'directora', 'profesor', 'profesor_admin', 'padre'
  nombre TEXT NOT NULL,
  descripcion TEXT,
  nivel_jerarquia INTEGER NOT NULL, -- 1=directora, 2=profesor_admin, 3=profesor, 4=padre
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_roles_codigo ON roles(codigo);

-- ============================================
-- 3. TABLA INTERMEDIA: ROLES ↔ PERMISOS
-- ============================================
CREATE TABLE IF NOT EXISTS roles_permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rol_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permiso_id UUID NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rol_id, permiso_id)
);

CREATE INDEX IF NOT EXISTS idx_roles_permisos_rol ON roles_permisos(rol_id);
CREATE INDEX IF NOT EXISTS idx_roles_permisos_permiso ON roles_permisos(permiso_id);

-- ============================================
-- 4. TABLA USUARIOS_PERMISOS (PERMISOS EXTRAS)
-- ============================================
CREATE TABLE IF NOT EXISTS usuarios_permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permiso_id UUID NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, permiso_id)
);

CREATE INDEX IF NOT EXISTS idx_usuarios_permisos_usuario ON usuarios_permisos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_permisos_permiso ON usuarios_permisos(permiso_id);

-- ============================================
-- 5. INSERTAR ROLES INICIALES
-- ============================================
INSERT INTO roles (codigo, nombre, descripcion, nivel_jerarquia) VALUES
  ('directora', 'Directora', 'Acceso total al sistema', 1),
  ('profesor_admin', 'Profesor Admin', 'Profesor con permisos administrativos', 2),
  ('profesor', 'Profesor', 'Acceso básico a bitácoras y alumnos asignados', 3),
  ('padre', 'Padre de Familia', 'Solo ve información de sus hijos', 4)
ON CONFLICT (codigo) DO NOTHING;

-- ============================================
-- 6. INSERTAR PERMISOS (29 PERMISOS)
-- ============================================
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
  -- ALUMNOS (6)
  ('ver_alumnos', 'Ver Alumnos', 'Listar y ver detalles de alumnos', 'alumnos', 'lectura'),
  ('crear_alumno', 'Crear Alumno', 'Dar de alta nuevos alumnos', 'alumnos', 'escritura'),
  ('editar_alumno', 'Editar Alumno', 'Modificar datos de alumnos', 'alumnos', 'escritura'),
  ('eliminar_alumno', 'Eliminar Alumno', 'Dar de baja alumnos', 'alumnos', 'eliminacion'),
  ('ver_personas_autorizadas', 'Ver Personas Autorizadas', 'Ver personas autorizadas para recoger alumnos', 'alumnos', 'lectura'),
  ('gestionar_personas_autorizadas', 'Gestionar Personas Autorizadas', 'Crear/editar personas autorizadas', 'alumnos', 'escritura'),

  -- PAGOS (4)
  ('ver_pagos', 'Ver Pagos', 'Consultar pagos de alumnos', 'pagos', 'lectura'),
  ('crear_pago', 'Crear Pago', 'Registrar nuevos pagos', 'pagos', 'escritura'),
  ('acreditar_pago', 'Acreditar Pago', 'Marcar pagos como pagados', 'pagos', 'escritura'),
  ('eliminar_pago', 'Eliminar Pago', 'Eliminar registros de pagos', 'pagos', 'eliminacion'),

  -- PROFESORES (4)
  ('ver_profesores', 'Ver Profesores', 'Listar profesores', 'profesores', 'lectura'),
  ('crear_profesor', 'Crear Profesor', 'Dar de alta profesores', 'profesores', 'escritura'),
  ('editar_profesor', 'Editar Profesor', 'Modificar datos de profesores', 'profesores', 'escritura'),
  ('gestionar_permisos', 'Gestionar Permisos', 'Asignar permisos a profesores', 'profesores', 'especial'),

  -- PADRES (3)
  ('ver_padres', 'Ver Padres', 'Listar padres de familia', 'padres', 'lectura'),
  ('crear_padre', 'Crear Padre', 'Dar de alta padres', 'padres', 'escritura'),
  ('editar_padre', 'Editar Padre', 'Modificar datos de padres', 'padres', 'escritura'),

  -- EVENTOS (3)
  ('ver_eventos', 'Ver Eventos', 'Consultar eventos', 'eventos', 'lectura'),
  ('crear_evento', 'Crear Evento', 'Registrar nuevos eventos', 'eventos', 'escritura'),
  ('editar_evento', 'Editar Evento', 'Modificar eventos', 'eventos', 'escritura'),

  -- INCIDENTES (4)
  ('ver_incidentes', 'Ver Incidentes', 'Consultar incidentes', 'incidentes', 'lectura'),
  ('crear_incidente', 'Crear Incidente', 'Reportar incidentes', 'incidentes', 'escritura'),
  ('editar_incidente', 'Editar Incidente', 'Modificar incidentes', 'incidentes', 'escritura'),
  ('ver_tipos_incidentes', 'Ver Tipos Incidentes', 'Gestionar catálogo de tipos', 'incidentes', 'especial'),

  -- CALIFICACIONES (2)
  ('ver_calificaciones', 'Ver Calificaciones', 'Consultar calificaciones', 'calificaciones', 'lectura'),
  ('editar_calificaciones', 'Editar Calificaciones', 'Capturar calificaciones', 'calificaciones', 'escritura'),

  -- BITÁCORA (1)
  ('ver_bitacora', 'Ver Bitácora', 'Gestionar bitácora diaria, control salidas, menú', 'bitacora', 'lectura'),

  -- ANUNCIOS (2)
  ('ver_anuncios', 'Ver Anuncios', 'Consultar anuncios', 'anuncios', 'lectura'),
  ('crear_anuncio', 'Crear Anuncio', 'Publicar anuncios', 'anuncios', 'escritura')
ON CONFLICT (codigo) DO NOTHING;

-- ============================================
-- 7. ASIGNAR TODOS LOS PERMISOS A DIRECTORA
-- ============================================
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'directora'),
  p.id
FROM permisos p
ON CONFLICT DO NOTHING;

-- ============================================
-- 8. ASIGNAR PERMISOS A PROFESOR ADMIN (17 PERMISOS)
-- ============================================
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'profesor_admin'),
  p.id
FROM permisos p
WHERE p.codigo IN (
  'ver_alumnos', 'crear_alumno', 'editar_alumno',
  'ver_personas_autorizadas', 'gestionar_personas_autorizadas',
  'ver_pagos',
  'ver_profesores',
  'ver_padres',
  'ver_eventos', 'crear_evento', 'editar_evento',
  'ver_incidentes', 'crear_incidente', 'editar_incidente',
  'ver_calificaciones', 'editar_calificaciones',
  'ver_bitacora',
  'ver_anuncios'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 9. ASIGNAR PERMISOS A PROFESOR (8 PERMISOS)
-- ============================================
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'profesor'),
  p.id
FROM permisos p
WHERE p.codigo IN (
  'ver_alumnos',
  'ver_incidentes', 'crear_incidente',
  'ver_calificaciones', 'editar_calificaciones',
  'ver_bitacora',
  'ver_anuncios',
  'ver_eventos'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 10. ASIGNAR PERMISOS A PADRE (5 PERMISOS)
-- ============================================
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'padre'),
  p.id
FROM permisos p
WHERE p.codigo IN (
  'ver_alumnos',      -- Solo sus hijos
  'ver_pagos',        -- Solo de sus hijos
  'ver_calificaciones', -- Solo de sus hijos
  'ver_anuncios',
  'ver_eventos'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 11. FUNCIÓN PARA VERIFICAR PERMISOS
-- ============================================
CREATE OR REPLACE FUNCTION usuario_tiene_permiso(
  p_usuario_id UUID,
  p_codigo_permiso TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_tiene_permiso BOOLEAN;
  v_rol_texto TEXT;
BEGIN
  -- Obtener rol del usuario
  SELECT rol INTO v_rol_texto
  FROM usuarios
  WHERE id = p_usuario_id;

  -- Si es directora, siempre tiene permiso
  IF v_rol_texto = 'directora' THEN
    RETURN TRUE;
  END IF;

  -- Verificar si tiene el permiso por su rol o por asignación directa
  SELECT EXISTS(
    -- Permisos por rol
    SELECT 1
    FROM usuarios u
    INNER JOIN roles r ON r.codigo = u.rol
    INNER JOIN roles_permisos rp ON rp.rol_id = r.id
    INNER JOIN permisos p ON p.id = rp.permiso_id
    WHERE u.id = p_usuario_id
      AND p.codigo = p_codigo_permiso
      AND p.activo = true
    
    UNION
    
    -- Permisos directos del usuario
    SELECT 1
    FROM usuarios_permisos up
    INNER JOIN permisos p ON p.id = up.permiso_id
    WHERE up.usuario_id = p_usuario_id
      AND p.codigo = p_codigo_permiso
      AND p.activo = true
  ) INTO v_tiene_permiso;

  RETURN COALESCE(v_tiene_permiso, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 12. VISTA PARA CONSULTAR PERMISOS (SIN RLS)
-- ============================================
DROP VIEW IF EXISTS v_permisos_usuario;

CREATE OR REPLACE VIEW v_permisos_usuario AS
SELECT DISTINCT
  u.id as usuario_id,
  u.email,
  u.nombre,
  u.rol as rol_texto,
  p.id as permiso_id,
  p.codigo as permiso_codigo,
  p.nombre as permiso_nombre,
  p.modulo,
  p.tipo
FROM usuarios u
-- Permisos del rol
LEFT JOIN roles r ON r.codigo = u.rol
LEFT JOIN roles_permisos rp ON rp.rol_id = r.id
LEFT JOIN permisos p ON p.id = rp.permiso_id
WHERE p.activo = true

UNION

-- Permisos directos del usuario
SELECT DISTINCT
  u.id as usuario_id,
  u.email,
  u.nombre,
  u.rol as rol_texto,
  p.id as permiso_id,
  p.codigo as permiso_codigo,
  p.nombre as permiso_nombre,
  p.modulo,
  p.tipo
FROM usuarios u
INNER JOIN usuarios_permisos up ON up.usuario_id = u.id
INNER JOIN permisos p ON p.id = up.permiso_id
WHERE p.activo = true;

-- ============================================
-- 13. RLS EN TABLAS (NO EN VISTAS)
-- ============================================

-- Habilitar RLS en tablas
ALTER TABLE permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles_permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios_permisos ENABLE ROW LEVEL SECURITY;

-- Políticas para permisos (todos pueden leer)
DROP POLICY IF EXISTS "Todos pueden ver permisos" ON permisos;
CREATE POLICY "Todos pueden ver permisos"
  ON permisos FOR SELECT
  USING (activo = true);

-- Políticas para roles (todos pueden leer)
DROP POLICY IF EXISTS "Todos pueden ver roles" ON roles;
CREATE POLICY "Todos pueden ver roles"
  ON roles FOR SELECT
  USING (activo = true);

-- Políticas para roles_permisos (todos pueden leer)
DROP POLICY IF EXISTS "Todos pueden ver roles_permisos" ON roles_permisos;
CREATE POLICY "Todos pueden ver roles_permisos"
  ON roles_permisos FOR SELECT
  USING (true);

-- Políticas para usuarios_permisos
DROP POLICY IF EXISTS "Ver propios permisos de usuario" ON usuarios_permisos;
CREATE POLICY "Ver propios permisos de usuario"
  ON usuarios_permisos FOR SELECT
  USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS "Directora gestiona permisos" ON usuarios_permisos;
CREATE POLICY "Directora gestiona permisos"
  ON usuarios_permisos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol = 'directora'
    )
  );

-- ============================================
-- 14. ACTUALIZAR ROL_ID EN USUARIOS
-- ============================================
-- Agregar columna rol_id si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'usuarios' AND column_name = 'rol_id'
  ) THEN
    ALTER TABLE usuarios ADD COLUMN rol_id UUID REFERENCES roles(id);
    CREATE INDEX idx_usuarios_rol_id ON usuarios(rol_id);
  END IF;
END $$;

-- Actualizar rol_id basado en rol texto
UPDATE usuarios u
SET rol_id = r.id
FROM roles r
WHERE u.rol = r.codigo
AND u.rol_id IS NULL;

-- ============================================
-- ✅ LISTO! SISTEMA DE PERMISOS CONFIGURADO
-- ============================================
