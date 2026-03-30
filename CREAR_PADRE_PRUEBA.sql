-- =====================================================
-- CREAR PADRE DE PRUEBA
-- =====================================================

-- IMPORTANTE: Primero debes crear el usuario en Supabase Authentication
-- 1. Ir a: Authentication → Users → Add User
-- 2. Email: padre.prueba@test.com
-- 3. Password: Padre123!
-- 4. Confirm user: ✅ (marcar como confirmado)

-- Luego ejecuta este SQL:
INSERT INTO usuarios (id, nombre, email, rol, telefono, activo)
SELECT 
    au.id,
    'Juan Pérez (Padre Prueba)',
    'padre.prueba@test.com',
    'padre',
    '5512345678',
    true
FROM auth.users au
WHERE au.email = 'padre.prueba@test.com'
ON CONFLICT (id) DO UPDATE 
SET rol = 'padre',
    nombre = 'Juan Pérez (Padre Prueba)';

-- =====================================================
-- CREDENCIALES:
-- =====================================================
-- Email: padre.prueba@test.com
-- Password: Padre123!
-- =====================================================

-- Verificar que se creó:
SELECT id, nombre, email, rol FROM usuarios WHERE email = 'padre.prueba@test.com';
