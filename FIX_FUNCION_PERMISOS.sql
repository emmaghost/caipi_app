-- ============================================
-- FIX: Corregir función usuario_tiene_permiso
-- ============================================
-- Este script solo actualiza la función sin tocar tus datos
-- Ejecuta esto en Supabase → SQL Editor

-- Eliminar función anterior
DROP FUNCTION IF EXISTS usuario_tiene_permiso(usuario_uid UUID, permiso_clave TEXT);
DROP FUNCTION IF EXISTS usuario_tiene_permiso(UUID, TEXT);

-- Crear función con nombres de parámetros correctos
CREATE OR REPLACE FUNCTION usuario_tiene_permiso(p_usuario_id UUID, p_codigo_permiso TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM usuarios u
    LEFT JOIN roles r ON u.rol = r.codigo
    LEFT JOIN roles_permisos rp ON r.id = rp.rol_id
    LEFT JOIN permisos p ON rp.permiso_id = p.id
    WHERE u.id = p_usuario_id
    AND (p.clave = p_codigo_permiso OR EXISTS (
      SELECT 1 FROM usuarios_permisos up
      JOIN permisos p2 ON up.permiso_id = p2.id
      WHERE up.usuario_id = p_usuario_id AND p2.clave = p_codigo_permiso
    ))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verificar que se creó correctamente
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'usuario_tiene_permiso' 
AND routine_schema = 'public';

-- Debe mostrar: usuario_tiene_permiso | FUNCTION
