-- ============================================
-- LIMPIAR EMAIL DUPLICADO
-- ============================================
-- Ejecuta esto en Supabase → SQL Editor

-- Ver qué usuarios tienen este email
SELECT id, email, rol, nombre, created_at 
FROM public.usuarios 
WHERE email = 'haneine@gmail.com';

-- Si ves que hay un registro incompleto o duplicado, bórralo:
-- (Descomenta la siguiente línea si quieres borrarlo)

-- DELETE FROM public.usuarios WHERE email = 'haneine@gmail.com';

-- NOTA: También debes borrar de Supabase Auth:
-- 1. Ve a: Authentication → Users
-- 2. Busca: haneine@gmail.com
-- 3. Click en los 3 puntos → Delete user
