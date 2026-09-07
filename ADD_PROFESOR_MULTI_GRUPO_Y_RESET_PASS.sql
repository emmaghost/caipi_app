-- =============================================================================
-- Multi-grupo profesoras + reset pass + desactivar con email mangled
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================

-- 1) Varios grupos por profesora
CREATE TABLE IF NOT EXISTS public.profesores_grados (
  profesor_id UUID NOT NULL REFERENCES public.profesores(id) ON DELETE CASCADE,
  grado_id UUID NOT NULL REFERENCES public.grados(id) ON DELETE CASCADE,
  PRIMARY KEY (profesor_id, grado_id)
);

CREATE INDEX IF NOT EXISTS idx_profesores_grados_grado
  ON public.profesores_grados(grado_id);

ALTER TABLE public.profesores_grados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profesores_grados_staff" ON public.profesores_grados;
CREATE POLICY "profesores_grados_staff" ON public.profesores_grados
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin', 'secretaria', 'caja')
        AND u.activo = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin', 'secretaria')
        AND u.activo = TRUE
    )
  );

-- Migrar grado_id actual → junction
INSERT INTO public.profesores_grados (profesor_id, grado_id)
SELECT p.id, p.grado_id
FROM public.profesores p
WHERE p.grado_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Helper: grados de un usuario profesor
CREATE OR REPLACE FUNCTION public.grados_de_profesor(p_usuario_id UUID DEFAULT auth.uid())
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT pg.grado_id
  FROM public.profesores p
  JOIN public.profesores_grados pg ON pg.profesor_id = p.id
  WHERE p.usuario_id = p_usuario_id
    AND p.activo = TRUE
  UNION
  SELECT p.grado_id
  FROM public.profesores p
  WHERE p.usuario_id = p_usuario_id
    AND p.activo = TRUE
    AND p.grado_id IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.grados_de_profesor(UUID) TO authenticated;

-- 2) Reiniciar contraseña (solo directora) → Caipi2026 por defecto
CREATE OR REPLACE FUNCTION public.reiniciar_password_usuario(
  p_usuario_id UUID,
  p_password TEXT DEFAULT 'Caipi2026'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.rol = 'directora' AND u.activo = TRUE
  ) THEN
    RAISE EXCEPTION 'Solo la directora puede reiniciar contraseñas';
  END IF;

  IF p_password IS NULL OR length(trim(p_password)) < 6 THEN
    RAISE EXCEPTION 'Contraseña inválida';
  END IF;

  UPDATE auth.users
  SET
    encrypted_password = crypt(trim(p_password), gen_salt('bf')),
    updated_at = now()
  WHERE id = p_usuario_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Usuario auth no encontrado';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reiniciar_password_usuario(UUID, TEXT) TO authenticated;

-- 3) Desactivar acceso: activo=false + email con _ para liberar el correo
CREATE OR REPLACE FUNCTION public.desactivar_usuario_escuela(p_usuario_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_email TEXT;
  v_nuevo TEXT;
  v_local TEXT;
  v_dom TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.rol IN ('directora', 'profesor_admin')
      AND u.activo = TRUE
  ) THEN
    RAISE EXCEPTION 'Sin permiso para desactivar usuarios';
  END IF;

  SELECT email INTO v_email FROM public.usuarios WHERE id = p_usuario_id;
  IF v_email IS NULL THEN
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  -- No tocar si ya está mangled
  IF position('_x' in lower(v_email)) = 0 THEN
    v_local := split_part(v_email, '@', 1);
    v_dom := split_part(v_email, '@', 2);
    IF v_dom IS NULL OR v_dom = '' THEN
      v_nuevo := v_email || '_x' || extract(epoch from now())::bigint::text;
    ELSE
      v_nuevo := v_local || '_x' || extract(epoch from now())::bigint::text || '@' || v_dom;
    END IF;
  ELSE
    v_nuevo := v_email;
  END IF;

  UPDATE public.usuarios
  SET activo = FALSE, email = v_nuevo
  WHERE id = p_usuario_id;

  UPDATE public.profesores
  SET activo = FALSE, updated_at = now()
  WHERE usuario_id = p_usuario_id;

  UPDATE auth.users
  SET
    email = v_nuevo,
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    updated_at = now()
  WHERE id = p_usuario_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.desactivar_usuario_escuela(UUID) TO authenticated;

-- Ampliar crear_usuario_escuela para caja y secretaria
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

  IF p_rol NOT IN (
    'padre', 'profesor', 'profesor_admin', 'secretaria', 'caja'
  ) THEN
    RAISE EXCEPTION 'Rol inválido: %', p_rol;
  END IF;

  IF v_email IS NULL OR v_email = '' OR position('@' in v_email) = 0 THEN
    RAISE EXCEPTION 'Correo inválido: %', p_email;
  END IF;

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
    id, instance_id, email, encrypted_password, email_confirmed_at,
    role, aud, created_at, updated_at, raw_app_meta_data, raw_user_meta_data
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
    v_user_id, v_email, p_nombre, p_apellidos, p_telefono, p_whatsapp, p_rol, true
  );

  RETURN v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.crear_usuario_escuela(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO authenticated;
