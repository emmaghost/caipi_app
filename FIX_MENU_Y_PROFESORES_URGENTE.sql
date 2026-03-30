-- ============================================
-- 🔧 FIX URGENTE: MENÚ VACÍO + PERMISOS + PROFESORES
-- ============================================
-- Este script corrige:
-- 1. Función usuario_tiene_permiso (para que el menú funcione)
-- 2. Asigna TODOS los permisos a rol 'directora'
-- 3. Verifica estructura de tablas
-- ============================================

-- 1. RECREAR FUNCIÓN DE PERMISOS (versión simplificada y funcional)
DROP FUNCTION IF EXISTS usuario_tiene_permiso(UUID, TEXT);

CREATE OR REPLACE FUNCTION usuario_tiene_permiso(
  p_usuario_id UUID,
  p_codigo_permiso TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_rol_usuario TEXT;
BEGIN
  -- Obtener el rol del usuario
  SELECT rol INTO v_rol_usuario
  FROM usuarios
  WHERE id = p_usuario_id;
  
  -- Si no tiene rol, no tiene permisos
  IF v_rol_usuario IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Si es directora, tiene TODOS los permisos
  IF v_rol_usuario = 'directora' THEN
    RETURN TRUE;
  END IF;
  
  -- Para otros roles, verificar en roles_permisos
  RETURN EXISTS (
    SELECT 1
    FROM roles r
    INNER JOIN roles_permisos rp ON r.id = rp.rol_id
    INNER JOIN permisos p ON rp.permiso_id = p.id
    WHERE r.codigo = v_rol_usuario
      AND p.clave = p_codigo_permiso
      AND p.activo = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. AGREGAR COLUMNA 'activo' A ROLES SI NO EXISTE
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'roles' AND column_name = 'activo'
  ) THEN
    ALTER TABLE roles ADD COLUMN activo BOOLEAN DEFAULT TRUE;
    COMMENT ON COLUMN roles.activo IS 'Indica si el rol está activo';
  END IF;
END $$;

-- 3. AGREGAR COLUMNA 'activo' A PERMISOS SI NO EXISTE
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'permisos' AND column_name = 'activo'
  ) THEN
    ALTER TABLE permisos ADD COLUMN activo BOOLEAN DEFAULT TRUE;
    COMMENT ON COLUMN permisos.activo IS 'Indica si el permiso está activo';
  END IF;
END $$;

-- 4. ASEGURAR QUE EL ROL 'directora' EXISTE
INSERT INTO roles (nombre, codigo, descripcion, nivel_jerarquia, activo)
VALUES ('Directora', 'directora', 'Acceso total al sistema', 1, true)
ON CONFLICT (codigo) DO UPDATE
SET nombre = 'Directora', activo = true;

-- 5. ASEGURAR QUE TODOS LOS PERMISOS BÁSICOS EXISTEN
INSERT INTO permisos (clave, nombre, descripcion, modulo, activo)
VALUES
  ('ver_alumnos', 'Ver Alumnos', 'Puede ver la lista de alumnos', 'alumnos', true),
  ('ver_pagos', 'Ver Pagos', 'Puede ver pagos', 'pagos', true),
  ('ver_profesores', 'Ver Profesores', 'Puede ver profesores', 'profesores', true),
  ('ver_padres', 'Ver Padres', 'Puede ver padres', 'padres', true),
  ('ver_eventos', 'Ver Eventos', 'Puede ver eventos', 'eventos', true),
  ('ver_incidentes', 'Ver Incidentes', 'Puede ver incidentes', 'incidentes', true),
  ('ver_tipos_incidentes', 'Ver Tipos de Incidentes', 'Puede ver tipos de incidentes', 'incidentes', true),
  ('ver_personas_autorizadas', 'Ver Personas Autorizadas', 'Puede ver personas autorizadas', 'seguridad', true),
  ('ver_bitacora', 'Ver Bitácora', 'Puede ver bitácora diaria', 'bitacora', true),
  ('ver_anuncios', 'Ver Anuncios', 'Puede ver anuncios', 'comunicacion', true),
  ('ver_calificaciones', 'Ver Calificaciones', 'Puede ver calificaciones', 'calificaciones', true)
ON CONFLICT (clave) DO UPDATE
SET activo = true;

-- 6. ASIGNAR TODOS LOS PERMISOS A 'directora'
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT 
  r.id as rol_id,
  p.id as permiso_id
FROM roles r
CROSS JOIN permisos p
WHERE r.codigo = 'directora'
  AND p.activo = true
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

-- 7. VERIFICACIÓN: Ver permisos del rol directora
SELECT 
  r.nombre as rol,
  p.clave as permiso,
  p.nombre as descripcion
FROM roles r
JOIN roles_permisos rp ON r.id = rp.rol_id
JOIN permisos p ON rp.permiso_id = p.id
WHERE r.codigo = 'directora'
ORDER BY p.modulo, p.clave;

-- ============================================
-- ✅ LISTO
-- ============================================

/*
DESPUÉS DE EJECUTAR:
1. ✅ La función usuario_tiene_permiso funciona
2. ✅ El menú se verá completo
3. ✅ La directora tiene TODOS los permisos

CONTRASEÑAS POR DEFECTO:
- Profesores: Caipi2026
- Padres: Caipi2026
- Se pueden cambiar en el perfil del usuario

ERROR "User already registered":
- Significa que el email ya existe
- Usa otro email o elimina el usuario existente
*/
