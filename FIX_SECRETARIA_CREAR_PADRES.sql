-- =============================================================================
-- Crear padres desde secretaria/directora SIN perder sesión (sin signUp en app)
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================

CREATE OR REPLACE FUNCTION public.crear_usuario_escuela(
  p_email     TEXT,
  p_password  TEXT,
  p_nombre    TEXT,
  p_apellidos TEXT DEFAULT NULL,
  p_telefono  TEXT DEFAULT NULL,
  p_whatsapp  TEXT DEFAULT NULL,
  p_rol       TEXT DEFAULT 'padre'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id   UUID;
  v_email     TEXT := lower(trim(p_email));
BEGIN
  IF NOT (
    public.caipi_es_directora_o_admin()
    OR public.caipi_puede_alta_alumnos()
  ) THEN
    RAISE EXCEPTION 'No tienes permiso para crear usuarios';
  END IF;

  IF p_rol NOT IN ('padre', 'profesor', 'profesor_admin') THEN
    RAISE EXCEPTION 'Rol inválido: %', p_rol;
  END IF;

  IF v_email IS NULL OR v_email = '' OR position('@' in v_email) = 0 THEN
    RAISE EXCEPTION 'Correo inválido: %', p_email;
  END IF;

  -- Ya existe perfil → reutilizar (2º papá / reintento en junta)
  SELECT u.id INTO v_user_id
  FROM public.usuarios u
  WHERE lower(trim(u.email)) = v_email
    AND u.rol = p_rol
  LIMIT 1;
  IF v_user_id IS NOT NULL THEN
    RETURN v_user_id;
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = v_email) THEN
    RAISE EXCEPTION 'Ya existe una cuenta con ese correo: %', v_email;
  END IF;

  v_user_id := gen_random_uuid();

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
    v_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    'authenticated',
    'authenticated',
    now(),
    now(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('nombre', p_nombre)
  );

  INSERT INTO public.usuarios (
    id, email, nombre, apellidos, telefono, whatsapp, rol, activo
  ) VALUES (
    v_user_id,
    v_email,
    p_nombre,
    p_apellidos,
    p_telefono,
    p_whatsapp,
    p_rol,
    true
  );

  RETURN v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.crear_usuario_escuela(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
