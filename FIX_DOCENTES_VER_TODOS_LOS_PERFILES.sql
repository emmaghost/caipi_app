-- ============================================================
-- Directora debe ver TODOS los perfiles de escuela (caja, etc.)
-- Ejecutar en Supabase → SQL Editor → Run
-- ============================================================

CREATE OR REPLACE FUNCTION public.caipi_es_directora_o_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.activo = TRUE
      AND u.rol IN ('directora', 'profesor_admin')
  );
$$;

REVOKE ALL ON FUNCTION public.caipi_es_directora_o_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.caipi_es_directora_o_admin() TO authenticated;

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ver usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_select" ON public.usuarios;
DROP POLICY IF EXISTS "Directora puede ver todos los usuarios" ON public.usuarios;
DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON public.usuarios;

-- Cada quien se ve a sí mismo; directora/admin ve a todos (incluye caja y secretaria)
CREATE POLICY "usuarios_select" ON public.usuarios
  FOR SELECT TO authenticated
  USING (
    auth.uid() = id
    OR public.caipi_es_directora_o_admin()
  );

-- Verificación rápida: perfiles de escuela
SELECT id, email, nombre, rol, activo
FROM public.usuarios
WHERE rol IN ('profesor', 'profesor_admin', 'caja', 'secretaria')
ORDER BY rol, nombre;
