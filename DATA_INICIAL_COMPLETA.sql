-- ============================================
-- DATA INICIAL COMPLETA - SISTEMA CAIPI
-- ============================================
-- Ejecuta este SQL en Supabase SQL Editor

-- ============================================
-- 1. GRADOS
-- ============================================
-- NOTA: Si esto falla, primero ejecuta ACTUALIZAR_GRADOS.sql

INSERT INTO grados (nombre, edad_minima, edad_maxima, cupo_maximo, activo, descripcion)
VALUES
  ('Maternal 1', 1, 2, 15, true, 'Niños de 1 a 2 años'),
  ('Maternal 2', 2, 3, 15, true, 'Niños de 2 a 3 años'),
  ('Maternal 3', 3, 4, 20, true, 'Niños de 3 a 4 años'),
  ('Kinder 1', 4, 5, 20, true, 'Niños de 4 a 5 años'),
  ('Kinder 2', 5, 6, 20, true, 'Niños de 5 a 6 años'),
  ('Kinder 3', 6, 7, 20, true, 'Niños de 6 a 7 años')
ON CONFLICT (nombre) DO UPDATE SET
  edad_minima = EXCLUDED.edad_minima,
  edad_maxima = EXCLUDED.edad_maxima,
  cupo_maximo = EXCLUDED.cupo_maximo,
  descripcion = EXCLUDED.descripcion,
  updated_at = NOW();

-- ============================================
-- 2. VERIFICAR USUARIO DIRECTORA
-- ============================================
-- Ya debes tener: viri@caipi.com

SELECT 
  u.id,
  u.email,
  u.rol,
  us.nombre,
  us.apellidos
FROM auth.users u
LEFT JOIN usuarios us ON u.id = us.id
WHERE u.email = 'viri@caipi.com';

-- Si no existe el registro en usuarios, créalo:
-- (Reemplaza 'TU_UUID_AQUI' con el UUID que aparece arriba)
/*
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, activo)
VALUES (
  'TU_UUID_AQUI',
  'viri@caipi.com',
  'directora',
  'Viridiana',
  'Directora',
  '0000000000',
  true
);
*/

-- ============================================
-- 3. CONCEPTOS DE PAGO (IMPORTANTE)
-- ============================================
-- Estos son los conceptos que se usan para los pagos

-- NO HAY TABLA DE CONCEPTOS, están hardcodeados:
-- 1. "Inscripción" - Anual
-- 2. "Seguro + Credencial" - Una vez
-- 3. "Colegiatura Enero" - Mensual
-- 4. "Colegiatura Febrero" - Mensual
-- ... etc para cada mes
-- 5. "Libros" - Opcional
-- 6. "Uniformes" - Opcional

-- ============================================
-- 4. VERIFICAR TABLAS VACÍAS
-- ============================================

-- Ver cuántos registros hay en cada tabla
SELECT 'grados' as tabla, COUNT(*) as registros FROM grados
UNION ALL
SELECT 'usuarios', COUNT(*) FROM usuarios
UNION ALL
SELECT 'alumnos', COUNT(*) FROM alumnos
UNION ALL
SELECT 'pagos', COUNT(*) FROM pagos
UNION ALL
SELECT 'profesores', COUNT(*) FROM profesores
UNION ALL
SELECT 'personas_autorizadas', COUNT(*) FROM personas_autorizadas
ORDER BY tabla;

-- ============================================
-- 5. DATOS DE PRUEBA (OPCIONAL)
-- ============================================

-- Crear un padre de prueba (para testing)
-- Primero crea el usuario en Authentication:
-- Email: padre.prueba@test.com
-- Password: Test1234

-- Luego inserta en la tabla usuarios:
/*
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp, activo)
VALUES (
  'UUID_DEL_AUTH_USER',
  'padre.prueba@test.com',
  'padre',
  'Juan',
  'Pérez',
  '5512345678',
  '5512345678',
  true
);
*/

-- ============================================
-- RESUMEN DE DATA NECESARIA
-- ============================================

/*
TABLAS QUE NECESITAN DATA INICIAL:
✅ grados - Ya insertamos 6 grados
✅ usuarios - Ya tienes 1 directora (viri@caipi.com)

TABLAS QUE SE LLENAN DESDE LA APP:
📝 alumnos - Se crean desde la app
📝 pagos - SE CREAN AUTOMÁTICAMENTE al crear alumno
📝 profesores - Se crean desde la app
📝 personas_autorizadas - Se agregan desde la app
📝 anuncios - Se crean desde la app
📝 calificaciones - Se crean desde la app
📝 incidentes - Se crean desde la app
📝 bitacora_diaria - Se crea desde la app
📝 menu_maternal - Se crea desde la app
📝 notificaciones - Se crean desde la app
📝 galeria - Se sube desde la app
*/
