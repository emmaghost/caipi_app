-- =============================================================================
-- Cuenta SECRETARIA: solo altas de alumnos/padres (juntas).
-- No borra datos. La beca solo la puede cambiar la directora.
-- =============================================================================

-- Permitir rol secretaria en usuarios
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT c.conname
    FROM pg_constraint c
    WHERE c.conrelid = 'public.usuarios'::regclass
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) ILIKE '%rol%'
  LOOP
    EXECUTE format('ALTER TABLE public.usuarios DROP CONSTRAINT %I', r.conname);
  END LOOP;
END $$;

ALTER TABLE public.usuarios
  ADD CONSTRAINT usuarios_rol_check
  CHECK (rol IN (
    'directora',
    'profesor_admin',
    'profesor',
    'padre',
    'secretaria'
  ));

DO $$
BEGIN
  INSERT INTO public.roles (codigo, nombre, descripcion, nivel_jerarquia)
  VALUES (
    'secretaria',
    'Secretaria',
    'Alta de alumnos y papás en junta. Sin pagos ni beca.',
    2
  )
  ON CONFLICT (codigo) DO NOTHING;
EXCEPTION
  WHEN undefined_table OR undefined_column OR unique_violation THEN
    NULL;
END $$;

CREATE OR REPLACE FUNCTION public.caipi_puede_alta_alumnos()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin', 'secretaria')
      AND COALESCE(activo, true) = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_puede_alta_alumnos() TO authenticated;

-- Secretaria ve / crea / edita alumnos (no borra)
DROP POLICY IF EXISTS "alumnos_select" ON public.alumnos;
DO $$
BEGIN
  IF to_regclass('public.alumnos_padres') IS NOT NULL THEN
    EXECUTE $p$
      CREATE POLICY "alumnos_select" ON public.alumnos
        FOR SELECT TO authenticated
        USING (
          padre_id = auth.uid()
          OR public.caipi_puede_alta_alumnos()
          OR public.caipi_es_directora_o_admin()
          OR EXISTS (
            SELECT 1 FROM public.alumnos_padres ap
            WHERE ap.alumno_id = alumnos.id AND ap.padre_id = auth.uid()
          )
          OR EXISTS (
            SELECT 1 FROM public.profesores p
            WHERE p.usuario_id = auth.uid()
              AND p.grado_id = alumnos.grado_id
              AND p.activo = true
          )
        )
    $p$;
  ELSE
    EXECUTE $p$
      CREATE POLICY "alumnos_select" ON public.alumnos
        FOR SELECT TO authenticated
        USING (
          padre_id = auth.uid()
          OR public.caipi_puede_alta_alumnos()
          OR public.caipi_es_directora_o_admin()
          OR EXISTS (
            SELECT 1 FROM public.profesores p
            WHERE p.usuario_id = auth.uid()
              AND p.grado_id = alumnos.grado_id
              AND p.activo = true
          )
        )
    $p$;
  END IF;
END $$;

DROP POLICY IF EXISTS "alumnos_insert" ON public.alumnos;
CREATE POLICY "alumnos_insert" ON public.alumnos
  FOR INSERT TO authenticated
  WITH CHECK (public.caipi_puede_alta_alumnos());

DROP POLICY IF EXISTS "alumnos_update" ON public.alumnos;
CREATE POLICY "alumnos_update" ON public.alumnos
  FOR UPDATE TO authenticated
  USING (public.caipi_puede_alta_alumnos())
  WITH CHECK (public.caipi_puede_alta_alumnos());

DO $$
BEGIN
  IF to_regclass('public.alumnos_padres') IS NULL THEN
    RETURN;
  END IF;
  EXECUTE 'DROP POLICY IF EXISTS "alumnos_padres_write" ON public.alumnos_padres';
  EXECUTE 'DROP POLICY IF EXISTS "alumnos_padres_select" ON public.alumnos_padres';
  EXECUTE $p$
    CREATE POLICY "alumnos_padres_write" ON public.alumnos_padres
      FOR ALL TO authenticated
      USING (public.caipi_puede_alta_alumnos())
      WITH CHECK (public.caipi_puede_alta_alumnos())
  $p$;
  EXECUTE $p$
    CREATE POLICY "alumnos_padres_select" ON public.alumnos_padres
      FOR SELECT TO authenticated
      USING (
        padre_id = auth.uid()
        OR public.caipi_puede_alta_alumnos()
        OR public.caipi_es_directora_o_admin()
        OR EXISTS (
          SELECT 1 FROM public.profesores p
          WHERE p.usuario_id = auth.uid() AND p.activo = true
        )
      )
  $p$;
END $$;

-- Crear papás (signUp + fila usuarios) desde secretaria
DROP POLICY IF EXISTS "usuarios_insert" ON public.usuarios;
CREATE POLICY "usuarios_insert" ON public.usuarios
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = id
    OR public.caipi_puede_alta_alumnos()
  );

-- Beca: solo la directora la cambia; secretaria no puede pisarla
CREATE OR REPLACE FUNCTION public.caipi_proteger_beca()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_es_directora boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ) INTO v_es_directora;

  IF TG_OP = 'INSERT' THEN
    IF NOT v_es_directora THEN
      NEW.beca_porcentaje := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.beca_porcentaje IS DISTINCT FROM OLD.beca_porcentaje
     AND NOT v_es_directora THEN
    NEW.beca_porcentaje := OLD.beca_porcentaje;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_proteger_beca ON public.alumnos;
CREATE TRIGGER trg_proteger_beca
  BEFORE INSERT OR UPDATE ON public.alumnos
  FOR EACH ROW
  EXECUTE FUNCTION public.caipi_proteger_beca();

NOTIFY pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- Secretaria NO ve ni edita pagos (el trigger de colegiaturas sí puede crearlos)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Ver pagos" ON public.pagos;
DO $$
BEGIN
  IF to_regclass('public.alumnos_padres') IS NOT NULL THEN
    EXECUTE $p$
      CREATE POLICY "Ver pagos" ON public.pagos
        FOR SELECT TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id = auth.uid()
              AND u.rol IN ('directora', 'profesor_admin')
          )
          OR EXISTS (
            SELECT 1 FROM public.alumnos a
            WHERE a.id = pagos.alumno_id
              AND (
                a.padre_id = auth.uid()
                OR EXISTS (
                  SELECT 1 FROM public.alumnos_padres ap
                  WHERE ap.alumno_id = a.id AND ap.padre_id = auth.uid()
                )
              )
          )
        )
    $p$;
  ELSE
    EXECUTE $p$
      CREATE POLICY "Ver pagos" ON public.pagos
        FOR SELECT TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM public.usuarios u
            WHERE u.id = auth.uid()
              AND u.rol IN ('directora', 'profesor_admin')
          )
          OR EXISTS (
            SELECT 1 FROM public.alumnos a
            WHERE a.id = pagos.alumno_id AND a.padre_id = auth.uid()
          )
        )
    $p$;
  END IF;
END $$;

DROP POLICY IF EXISTS "Editar pagos" ON public.pagos;
CREATE POLICY "Editar pagos" ON public.pagos
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ---------------------------------------------------------------------------
-- Usuario listo para el iPad de junta
-- Email: secretaria@caipi.com
-- Password: Caipi2026
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_id uuid;
  v_email text := 'secretaria@caipi.com';
  v_pass text := 'Caipi2026';
  v_instance uuid := '00000000-0000-0000-0000-000000000000';
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE lower(email) = v_email;
  IF v_id IS NULL THEN
    v_id := gen_random_uuid();
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    ) VALUES (
      v_id,
      v_instance,
      'authenticated',
      'authenticated',
      v_email,
      crypt(v_pass, gen_salt('bf')),
      now(),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      jsonb_build_object('nombre', 'Secretaria CAIPI'),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );

    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_id,
      jsonb_build_object('sub', v_id::text, 'email', v_email),
      'email',
      v_id::text,
      now(),
      now(),
      now()
    );
  ELSE
    UPDATE auth.users
    SET
      encrypted_password = crypt(v_pass, gen_salt('bf')),
      email_confirmed_at = COALESCE(email_confirmed_at, now()),
      updated_at = now()
    WHERE id = v_id;
  END IF;

  INSERT INTO public.usuarios (id, email, nombre, rol, activo)
  VALUES (v_id, v_email, 'Secretaria CAIPI', 'secretaria', true)
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        nombre = EXCLUDED.nombre,
        rol = 'secretaria',
        activo = true;
END $$;

SELECT id, email, rol, nombre, activo
FROM public.usuarios
WHERE email = 'secretaria@caipi.com';
