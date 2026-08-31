-- =============================================================================
-- Cuenta demo para revisores de Google Play Console
-- Ejecutar en Supabase → SQL Editor (Run)
-- =============================================================================
-- Email:    reviwer@caipi.com
-- Password: reviwer2026Caipi
-- Rol:      directora (acceso completo excepto lo que la app limite por rol)
-- =============================================================================

DO $$
DECLARE
  v_id uuid;
  v_email text := 'reviwer@caipi.com';
  v_pass text := 'reviwer2026Caipi';
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
      jsonb_build_object('nombre', 'Google Play Reviewer'),
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

  INSERT INTO public.usuarios (id, email, nombre, apellidos, rol, activo)
  VALUES (
    v_id,
    v_email,
    'Google Play',
    'Reviewer',
    'directora',
    true
  )
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        nombre = EXCLUDED.nombre,
        apellidos = EXCLUDED.apellidos,
        rol = 'directora',
        activo = true;
END $$;

SELECT id, email, rol, nombre, apellidos, activo
FROM public.usuarios
WHERE email = 'reviwer@caipi.com';
