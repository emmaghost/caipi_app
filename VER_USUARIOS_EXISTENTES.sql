-- =====================================================
-- VERIFICAR USUARIOS EXISTENTES
-- =====================================================

-- 1. Ver todos los usuarios registrados
SELECT 
    id,
    nombre,
    email,
    rol,
    telefono,
    created_at
FROM usuarios
ORDER BY created_at DESC;

-- 2. Ver usuarios en auth.users (tabla de autenticación de Supabase)
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users
ORDER BY created_at DESC;

-- 3. Verificar si existe la directora
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM usuarios WHERE rol = 'directora') 
        THEN '✅ SÍ existe usuario DIRECTORA'
        ELSE '❌ NO existe usuario DIRECTORA - debes crearlo'
    END as status;

-- =====================================================
-- SI NO EXISTE LA DIRECTORA, CREA UNA:
-- =====================================================
-- Descomenta estas líneas y ejecuta:

/*
INSERT INTO usuarios (
    id,
    nombre,
    email,
    rol,
    telefono,
    activo
) VALUES (
    gen_random_uuid(),
    'Virginia Directora',
    'directora@caipi.com',
    'directora',
    '5540504618',
    true
) ON CONFLICT (email) DO NOTHING;
*/

-- =====================================================
-- NOTA IMPORTANTE:
-- =====================================================
-- Para usar este usuario necesitas:
-- 1. Crear la cuenta en Supabase Authentication
-- 2. Usar el email: directora@caipi.com
-- 3. Password: CAIPI2026! (o el que prefieras)
