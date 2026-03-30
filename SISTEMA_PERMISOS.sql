-- ============================================
-- SISTEMA DE PERMISOS - CAIPI
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
-- 4. TABLA INTERMEDIA: USUARIOS ↔ PERMISOS ADICIONALES
-- ============================================
CREATE TABLE IF NOT EXISTS usuarios_permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  permiso_id UUID NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
  otorgado_por UUID REFERENCES usuarios(id),
  fecha_otorgamiento TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, permiso_id)
);

CREATE INDEX IF NOT EXISTS idx_usuarios_permisos_usuario ON usuarios_permisos(usuario_id);

-- ============================================
-- 5. MODIFICAR TABLA USUARIOS (AGREGAR ROL_ID)
-- ============================================
-- Agregar columna rol_id (para referencias)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS rol_id UUID REFERENCES roles(id);

-- ============================================
-- 6. INSERTAR ROLES BASE
-- ============================================
INSERT INTO roles (codigo, nombre, descripcion, nivel_jerarquia) VALUES
('directora', 'Directora', 'Acceso total al sistema', 1),
('profesor_admin', 'Profesor Administrador', 'Profesor con permisos administrativos', 2),
('profesor', 'Profesor', 'Acceso limitado a su grupo', 3),
('padre', 'Padre/Madre', 'Solo ve información de sus hijos', 4)
ON CONFLICT (codigo) DO NOTHING;

-- ============================================
-- 7. INSERTAR PERMISOS (CATÁLOGO COMPLETO)
-- ============================================

-- MÓDULO: ALUMNOS
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_alumnos', 'Ver Alumnos', 'Ver lista de alumnos', 'alumnos', 'lectura'),
('ver_alumno_detalle', 'Ver Detalle de Alumno', 'Ver información completa de un alumno', 'alumnos', 'lectura'),
('crear_alumno', 'Crear Alumno', 'Registrar nuevo alumno', 'alumnos', 'escritura'),
('editar_alumno', 'Editar Alumno', 'Modificar información del alumno', 'alumnos', 'escritura'),
('eliminar_alumno', 'Eliminar Alumno', 'Dar de baja alumno', 'alumnos', 'eliminacion')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: PAGOS
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_pagos', 'Ver Pagos', 'Ver lista de pagos', 'pagos', 'lectura'),
('acreditar_pago', 'Acreditar Pago', 'Marcar pago como realizado', 'pagos', 'escritura'),
('crear_pago', 'Crear Pago', 'Generar nuevo pago', 'pagos', 'escritura'),
('ver_reportes_pagos', 'Ver Reportes de Pagos', 'Acceso a reportes financieros', 'pagos', 'especial')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: PROFESORES
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_profesores', 'Ver Profesores', 'Ver lista de profesoras', 'profesores', 'lectura'),
('crear_profesor', 'Crear Profesor', 'Registrar nueva profesora', 'profesores', 'escritura'),
('editar_profesor', 'Editar Profesor', 'Modificar información de profesora', 'profesores', 'escritura'),
('asignar_permisos', 'Asignar Permisos', 'Otorgar permisos especiales a profesoras', 'profesores', 'especial')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: PADRES
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_padres', 'Ver Padres', 'Ver lista de padres de familia', 'padres', 'lectura'),
('crear_padre', 'Crear Padre', 'Registrar nuevo padre/madre', 'padres', 'escritura'),
('editar_padre', 'Editar Padre', 'Modificar información de padre', 'padres', 'escritura')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: EVENTOS
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_eventos', 'Ver Eventos', 'Ver calendario de eventos', 'eventos', 'lectura'),
('crear_evento', 'Crear Evento', 'Registrar nuevo evento', 'eventos', 'escritura'),
('editar_evento', 'Editar Evento', 'Modificar evento', 'eventos', 'escritura'),
('eliminar_evento', 'Eliminar Evento', 'Cancelar evento', 'eventos', 'eliminacion')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: INCIDENTES
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_incidentes', 'Ver Incidentes', 'Ver incidentes de alumnos', 'incidentes', 'lectura'),
('crear_incidente', 'Crear Incidente', 'Registrar nuevo incidente', 'incidentes', 'escritura'),
('ver_tipos_incidentes', 'Ver Tipos de Incidentes', 'Ver catálogo de tipos', 'incidentes', 'lectura'),
('gestionar_tipos_incidentes', 'Gestionar Tipos', 'Crear/editar tipos de incidentes', 'incidentes', 'especial')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: PERSONAS AUTORIZADAS
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_personas_autorizadas', 'Ver Personas Autorizadas', 'Ver personas autorizadas', 'autorizados', 'lectura'),
('gestionar_personas_autorizadas', 'Gestionar Personas Autorizadas', 'Agregar/editar personas autorizadas', 'autorizados', 'escritura')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: BITÁCORA
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_bitacora', 'Ver Bitácora', 'Ver bitácora diaria', 'bitacora', 'lectura'),
('crear_bitacora', 'Crear Bitácora', 'Registrar entrada en bitácora', 'bitacora', 'escritura')
ON CONFLICT (codigo) DO NOTHING;

-- MÓDULO: ANUNCIOS
INSERT INTO permisos (codigo, nombre, descripcion, modulo, tipo) VALUES
('ver_anuncios', 'Ver Anuncios', 'Ver anuncios', 'anuncios', 'lectura'),
('crear_anuncio', 'Crear Anuncio', 'Publicar nuevo anuncio', 'anuncios', 'escritura')
ON CONFLICT (codigo) DO NOTHING;

-- ============================================
-- 8. ASIGNAR PERMISOS A ROLES
-- ============================================

-- DIRECTORA: TODOS LOS PERMISOS
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'directora'),
  p.id
FROM permisos p
WHERE p.activo = true
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

-- PROFESOR ADMIN: CASI TODOS (excepto gestionar profesores y asignar permisos)
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'profesor_admin'),
  p.id
FROM permisos p
WHERE p.activo = true
  AND p.codigo NOT IN ('asignar_permisos', 'crear_profesor', 'editar_profesor', 'eliminar_alumno')
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

-- PROFESOR: PERMISOS BÁSICOS
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'profesor'),
  p.id
FROM permisos p
WHERE p.codigo IN (
  'ver_alumnos',
  'ver_alumno_detalle',
  'ver_eventos',
  'crear_incidente',
  'ver_incidentes',
  'crear_bitacora',
  'ver_bitacora',
  'ver_anuncios',
  'ver_personas_autorizadas'
)
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

-- PADRE: SOLO LECTURA DE SUS HIJOS
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  (SELECT id FROM roles WHERE codigo = 'padre'),
  p.id
FROM permisos p
WHERE p.codigo IN (
  'ver_alumno_detalle',
  'ver_eventos',
  'ver_incidentes',
  'ver_anuncios'
)
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

-- ============================================
-- 9. FUNCIÓN PARA VERIFICAR PERMISOS
-- ============================================
CREATE OR REPLACE FUNCTION usuario_tiene_permiso(
  p_usuario_id UUID,
  p_codigo_permiso TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_tiene_permiso BOOLEAN;
BEGIN
  -- Verificar si el usuario tiene el permiso por rol o individual
  SELECT EXISTS (
    -- Por rol
    SELECT 1
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.id
    JOIN roles_permisos rp ON r.id = rp.rol_id
    JOIN permisos p ON rp.permiso_id = p.id
    WHERE u.id = p_usuario_id
      AND p.codigo = p_codigo_permiso
      AND p.activo = true
    
    UNION
    
    -- Por permiso individual
    SELECT 1
    FROM usuarios_permisos up
    JOIN permisos p ON up.permiso_id = p.id
    WHERE up.usuario_id = p_usuario_id
      AND p.codigo = p_codigo_permiso
      AND p.activo = true
  ) INTO v_tiene_permiso;
  
  RETURN COALESCE(v_tiene_permiso, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 10. VISTA PARA OBTENER PERMISOS DE USUARIO
-- ============================================
CREATE OR REPLACE VIEW v_permisos_usuario AS
SELECT DISTINCT
  u.id as usuario_id,
  u.email,
  u.nombre,
  u.rol as rol_texto,
  r.codigo as rol_codigo,
  r.nombre as rol_nombre,
  r.nivel_jerarquia,
  p.codigo as permiso_codigo,
  p.nombre as permiso_nombre,
  p.modulo,
  p.tipo as permiso_tipo,
  CASE 
    WHEN up.id IS NOT NULL THEN 'individual'
    ELSE 'rol'
  END as origen_permiso
FROM usuarios u
LEFT JOIN roles r ON u.rol_id = r.id
LEFT JOIN roles_permisos rp ON r.id = rp.rol_id
LEFT JOIN permisos p ON rp.permiso_id = p.id
LEFT JOIN usuarios_permisos up ON u.id = up.usuario_id AND p.id = up.permiso_id
WHERE p.activo = true OR p.id IS NULL;

-- ============================================
-- 11. RLS PARA TABLAS DE PERMISOS
-- ============================================
ALTER TABLE permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles_permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios_permisos ENABLE ROW LEVEL SECURITY;

-- Solo directora puede ver/editar permisos
CREATE POLICY "Solo directora puede gestionar permisos"
  ON permisos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol = 'directora'
    )
  );

CREATE POLICY "Solo directora puede gestionar roles"
  ON roles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol = 'directora'
    )
  );

-- Todos pueden ver sus propios permisos
CREATE POLICY "Ver propios permisos"
  ON v_permisos_usuario FOR SELECT
  USING (usuario_id = auth.uid());

-- ============================================
-- 12. ACTUALIZAR USUARIOS EXISTENTES CON ROL_ID
-- ============================================
UPDATE usuarios 
SET rol_id = (SELECT id FROM roles WHERE codigo = usuarios.rol)
WHERE rol_id IS NULL;

-- ============================================
-- VERIFICACIÓN
-- ============================================
SELECT 
  'Roles' as tabla, 
  COUNT(*) as registros 
FROM roles
UNION ALL
SELECT 'Permisos', COUNT(*) FROM permisos
UNION ALL
SELECT 'Roles-Permisos', COUNT(*) FROM roles_permisos;

-- Ver permisos por rol
SELECT 
  r.nombre as rol,
  COUNT(rp.permiso_id) as total_permisos
FROM roles r
LEFT JOIN roles_permisos rp ON r.id = rp.rol_id
GROUP BY r.nombre
ORDER BY r.nivel_jerarquia;
