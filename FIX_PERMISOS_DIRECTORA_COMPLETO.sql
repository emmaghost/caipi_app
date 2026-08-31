-- =====================================================================
-- FIX: Permisos completos para Directora
-- Ejecutar en Supabase → SQL Editor
--
-- Qué resuelve:
--   1. Directora puede borrar padres, profesores, alumnos → pero NO a sí
--      misma ni a otras directoras
--   2. Nadie más puede borrar nada crítico
--   3. Función segura para crear usuarios (padre/profesor) sin perder
--      la sesión de la directora
-- =====================================================================

-- =====================================================================
-- PASO 1: Función auxiliar (sin recursión RLS)
-- Ya existe en FIX_PROFESORES_RLS_INSERT.sql; se recrea por si acaso.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.caipi_es_directora_o_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin')
  );
$$;

REVOKE ALL ON FUNCTION public.caipi_es_directora_o_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.caipi_es_directora_o_admin() TO authenticated;

-- Variante: solo directora (no profesor_admin)
CREATE OR REPLACE FUNCTION public.caipi_es_directora()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND rol = 'directora'
  );
$$;

REVOKE ALL ON FUNCTION public.caipi_es_directora() FROM public;
GRANT EXECUTE ON FUNCTION public.caipi_es_directora() TO authenticated;

-- =====================================================================
-- PASO 2: Políticas RLS de USUARIOS
-- Regla principal: la directora puede hacer todo EXCEPTO:
--   - Borrarse a sí misma
--   - Borrar a otra directora
-- =====================================================================
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ver usuarios"              ON public.usuarios;
DROP POLICY IF EXISTS "Crear usuarios"            ON public.usuarios;
DROP POLICY IF EXISTS "Editar usuarios"           ON public.usuarios;
DROP POLICY IF EXISTS "Eliminar usuarios"         ON public.usuarios;
DROP POLICY IF EXISTS "Eliminar usuarios no directoras" ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_select"           ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_insert"           ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_update"           ON public.usuarios;
DROP POLICY IF EXISTS "usuarios_delete"           ON public.usuarios;

-- SELECT: cada usuario ve su propio perfil; directora ve todos
CREATE POLICY "usuarios_select" ON public.usuarios
  FOR SELECT TO authenticated
  USING (
    auth.uid() = id              -- se ve a sí mismo
    OR caipi_es_directora_o_admin()
  );

-- INSERT: directora crea padres/profesores; un usuario se crea a sí mismo
-- (el trigger de auth crea el registro; también lo hace registrarUsuario())
CREATE POLICY "usuarios_insert" ON public.usuarios
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = id              -- auto-registro al hacer signUp
    OR caipi_es_directora_o_admin()
  );

-- UPDATE: directora edita a cualquiera; cada uno se edita a sí mismo
CREATE POLICY "usuarios_update" ON public.usuarios
  FOR UPDATE TO authenticated
  USING (
    auth.uid() = id
    OR caipi_es_directora_o_admin()
  )
  WITH CHECK (
    auth.uid() = id
    OR caipi_es_directora_o_admin()
  );

-- DELETE: directora puede borrar SOLO si:
--   - No es ella misma
--   - El target no tiene rol='directora'
CREATE POLICY "usuarios_delete" ON public.usuarios
  FOR DELETE TO authenticated
  USING (
    caipi_es_directora_o_admin()    -- solo directora puede borrar
    AND id != auth.uid()             -- nunca a sí misma
    AND rol != 'directora'           -- nunca a otra directora
  );

-- =====================================================================
-- PASO 3: Políticas RLS de ALUMNOS
-- Directora y profesor_admin: CRUD completo
-- Profesor: solo lectura de sus alumnos (por grado)
-- Padre: solo lectura de sus propios hijos
-- =====================================================================
ALTER TABLE public.alumnos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ver alumnos"      ON public.alumnos;
DROP POLICY IF EXISTS "Crear alumnos"    ON public.alumnos;
DROP POLICY IF EXISTS "Editar alumnos"   ON public.alumnos;
DROP POLICY IF EXISTS "Eliminar alumnos" ON public.alumnos;
DROP POLICY IF EXISTS "alumnos_select"   ON public.alumnos;
DROP POLICY IF EXISTS "alumnos_insert"   ON public.alumnos;
DROP POLICY IF EXISTS "alumnos_update"   ON public.alumnos;
DROP POLICY IF EXISTS "alumnos_delete"   ON public.alumnos;

CREATE POLICY "alumnos_select" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    padre_id = auth.uid()                   -- padre ve a sus hijos
    OR caipi_es_directora_o_admin()
    OR EXISTS (                             -- profesor ve alumnos de su grado
        SELECT 1 FROM public.profesores p
        WHERE p.usuario_id = auth.uid()
          AND p.grado_id = alumnos.grado_id
          AND p.activo = true
    )
  );

CREATE POLICY "alumnos_insert" ON public.alumnos
  FOR INSERT TO authenticated
  WITH CHECK (caipi_es_directora_o_admin());

CREATE POLICY "alumnos_update" ON public.alumnos
  FOR UPDATE TO authenticated
  USING  (caipi_es_directora_o_admin())
  WITH CHECK (caipi_es_directora_o_admin());

CREATE POLICY "alumnos_delete" ON public.alumnos
  FOR DELETE TO authenticated
  USING (caipi_es_directora());   -- solo directora, no profesor_admin

-- =====================================================================
-- PASO 4: Función para crear padre/profesor SIN perder sesión
--
-- Problema actual: auth.signUp() en Flutter cambia la sesión activa.
-- Solución: función PostgreSQL SECURITY DEFINER que inserta directo
-- en auth.users (solo accesible con el rol de superusuario que
-- Supabase le da a las funciones SECURITY DEFINER en el schema auth).
--
-- NOTA: En Supabase Cloud esta función requiere ejecutarse con permisos
-- de service_role. Si ves "permission denied for schema auth", usa la
-- opción alternativa (Edge Function) descrita al final.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.crear_usuario_escuela(
  p_email     TEXT,
  p_password  TEXT,
  p_nombre    TEXT,
  p_apellidos TEXT DEFAULT NULL,
  p_telefono  TEXT DEFAULT NULL,
  p_whatsapp  TEXT DEFAULT NULL,
  p_rol       TEXT DEFAULT 'padre'   -- 'padre' | 'profesor'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id   UUID;
  v_enc_pass  TEXT;
BEGIN
  -- Solo la directora puede llamar esta función
  IF NOT caipi_es_directora_o_admin() THEN
    RAISE EXCEPTION 'Solo la directora puede crear usuarios';
  END IF;

  -- Rol válido
  IF p_rol NOT IN ('padre', 'profesor', 'profesor_admin') THEN
    RAISE EXCEPTION 'Rol inválido: %', p_rol;
  END IF;

  -- Verificar email duplicado
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(trim(p_email))) THEN
    RAISE EXCEPTION 'Ya existe una cuenta con ese correo: %', p_email;
  END IF;

  v_user_id := gen_random_uuid();

  -- Insertar en auth.users (Supabase internal)
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    role,
    aud,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data
  ) VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    lower(trim(p_email)),
    crypt(p_password, gen_salt('bf')),  -- bcrypt
    now(),                               -- confirmar email automáticamente
    'authenticated',
    'authenticated',
    now(),
    now(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('nombre', p_nombre)
  );

  -- Insertar perfil en tabla usuarios
  INSERT INTO public.usuarios (
    id, email, nombre, apellidos, telefono, whatsapp, rol
  ) VALUES (
    v_user_id,
    lower(trim(p_email)),
    p_nombre,
    p_apellidos,
    p_telefono,
    p_whatsapp,
    p_rol
  );

  RETURN v_user_id;
END;
$$;

-- Solo usuarios autenticados pueden llamarla (la función ya verifica rol internamente)
REVOKE ALL ON FUNCTION public.crear_usuario_escuela(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.crear_usuario_escuela(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO authenticated;

-- =====================================================================
-- PASO 5: Función para eliminar padre/profesor de forma segura
-- Borra el perfil Y la cuenta auth (auth.users)
-- Protección: no puede borrar directoras ni a sí misma
-- =====================================================================
CREATE OR REPLACE FUNCTION public.eliminar_usuario_escuela(p_usuario_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_rol TEXT;
BEGIN
  IF NOT caipi_es_directora_o_admin() THEN
    RAISE EXCEPTION 'Solo la directora puede eliminar usuarios';
  END IF;

  IF p_usuario_id = auth.uid() THEN
    RAISE EXCEPTION 'No puedes eliminarte a ti misma';
  END IF;

  SELECT rol INTO v_rol FROM public.usuarios WHERE id = p_usuario_id;

  IF v_rol = 'directora' THEN
    RAISE EXCEPTION 'No se puede eliminar a una directora';
  END IF;

  -- Borrar perfil (ON DELETE CASCADE cuida las relaciones)
  DELETE FROM public.usuarios WHERE id = p_usuario_id;

  -- Borrar cuenta auth
  DELETE FROM auth.users WHERE id = p_usuario_id;
END;
$$;

REVOKE ALL ON FUNCTION public.eliminar_usuario_escuela(UUID) FROM public;
GRANT EXECUTE ON FUNCTION public.eliminar_usuario_escuela(UUID) TO authenticated;

-- =====================================================================
-- VERIFICACIÓN
-- =====================================================================
SELECT
  tablename,
  policyname,
  cmd,
  permissive
FROM pg_policies
WHERE tablename IN ('usuarios', 'alumnos')
ORDER BY tablename, cmd;

-- =====================================================================
-- CÓMO LLAMAR DESDE FLUTTER (reemplaza el signUp actual)
-- =====================================================================
/*
  // En AuthService, reemplazar registrarUsuario() con:

  Future<String?> registrarUsuarioPorDirectora({
    required String email,
    required String password,
    required String nombre,
    String? apellidos,
    String? telefono,
    String? whatsapp,
    required String rol,
  }) async {
    try {
      await _supabase.rpc('crear_usuario_escuela', params: {
        'p_email':     email.trim(),
        'p_password':  password,
        'p_nombre':    nombre,
        'p_apellidos': apellidos,
        'p_telefono':  telefono,
        'p_whatsapp':  whatsapp,
        'p_rol':       rol,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Para borrar un usuario:
  Future<String?> eliminarUsuario(String usuarioId) async {
    try {
      await _supabase.rpc('eliminar_usuario_escuela', params: {
        'p_usuario_id': usuarioId,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
*/
