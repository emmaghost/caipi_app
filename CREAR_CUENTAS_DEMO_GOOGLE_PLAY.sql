-- =============================================================================
-- CUENTAS DEMO — Google Play Console (revisores)
-- Ejecutar TODO en Supabase → SQL Editor → Run
-- =============================================================================
--
-- 1) DIRECTORA DEMO
--    Email:    reviwer@caipi.com
--    Password: reviwer2026Caipi
--    Rol:      directora (admin completo)
--
-- 2) PADRE DEMO
--    Email:    padre.demo@caipi.com
--    Password: reviwer2026Caipi
--    Rol:      padre
--    Hijo:     Sofía Demo Google Play (Kinder 1)
--    Incluye:  1 colegiatura pendiente + 1 pagada + bitácora de hoy
--
-- ⚠️ NO uses viri@caipi.com ni cuentas reales para Google.
-- =============================================================================

-- Hash bcrypt de "reviwer2026Caipi" (sin depender de pgcrypto / gen_salt)
-- Si cambias la contraseña demo, genera otro hash o usa CREAR_CUENTAS_DEMO_GOOGLE_PLAY_PLAN_B.sql

CREATE OR REPLACE FUNCTION public._caipi_demo_upsert_auth_user(
  p_email text,
  p_password_hash text,
  p_nombre_meta text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id uuid;
  v_email text := lower(trim(p_email));
  v_instance uuid := '00000000-0000-0000-0000-000000000000';
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE lower(email) = v_email;

  IF v_id IS NULL THEN
    v_id := gen_random_uuid();

    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      v_id, v_instance, 'authenticated', 'authenticated', v_email,
      p_password_hash,
      now(),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      jsonb_build_object('nombre', p_nombre_meta),
      now(), now(), '', '', '', ''
    );

    INSERT INTO auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_id,
      jsonb_build_object('sub', v_id::text, 'email', v_email),
      'email', v_id::text, now(), now(), now()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = p_password_hash,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_id;
  END IF;

  RETURN v_id;
END;
$$;

DO $$
DECLARE
  -- Password demo: reviwer2026Caipi
  v_pass_hash text := '$2b$10$7CcFtR7XAetOxpebtbdWWecxXkfb2Zib9zYzlEG4TXX3qM1gAd5F2';
  v_dir_id uuid;
  v_padre_id uuid;
  v_alumno_id uuid;
  v_grado_id uuid;
  v_pago_pend uuid;
  v_pago_ok uuid;
BEGIN
  -- ── 1. Directora demo ─────────────────────────────────────────────────────
  v_dir_id := public._caipi_demo_upsert_auth_user(
    'reviwer@caipi.com', v_pass_hash, 'Google Play Reviewer'
  );

  INSERT INTO public.usuarios (id, email, nombre, apellidos, rol, activo)
  VALUES (v_dir_id, 'reviwer@caipi.com', 'Google Play', 'Reviewer', 'directora', true)
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, nombre = EXCLUDED.nombre, apellidos = EXCLUDED.apellidos,
        rol = 'directora', activo = true;

  -- ── 2. Padre demo ─────────────────────────────────────────────────────────
  v_padre_id := public._caipi_demo_upsert_auth_user(
    'padre.demo@caipi.com', v_pass_hash, 'Padre Demo Google Play'
  );

  INSERT INTO public.usuarios (
    id, email, nombre, apellidos, telefono, whatsapp, rol, activo,
    acceso_app_modo
  ) VALUES (
    v_padre_id, 'padre.demo@caipi.com', 'Carlos', 'Demo Padre',
    '5550000001', '5550000001', 'padre', true, 'desbloqueado'
  )
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, nombre = EXCLUDED.nombre, apellidos = EXCLUDED.apellidos,
        telefono = EXCLUDED.telefono, whatsapp = EXCLUDED.whatsapp,
        rol = 'padre', activo = true, acceso_app_modo = 'desbloqueado';

  -- QR permanente padre (recogida)
  UPDATE public.usuarios
  SET qr_permanente = COALESCE(qr_permanente, 'QR-PADRE-DEMO-' || left(v_padre_id::text, 8))
  WHERE id = v_padre_id;

  -- ── 3. Grado para el niño demo ────────────────────────────────────────────
  SELECT id INTO v_grado_id
  FROM public.grados
  WHERE activo = true AND nombre ILIKE '%kinder 1%'
  ORDER BY nombre
  LIMIT 1;

  IF v_grado_id IS NULL THEN
    SELECT id INTO v_grado_id FROM public.grados WHERE activo = true ORDER BY nombre LIMIT 1;
  END IF;

  -- ── 4. Alumno demo (reutilizar si ya existe) ──────────────────────────────
  SELECT id INTO v_alumno_id
  FROM public.alumnos
  WHERE nombre ILIKE 'Sofía' AND apellidos ILIKE '%Demo Google%'
  LIMIT 1;

  IF v_alumno_id IS NULL THEN
    v_alumno_id := gen_random_uuid();
    INSERT INTO public.alumnos (
      id, nombre, apellidos, fecha_nacimiento, genero, grado_id, padre_id,
      activo, plan_pagos, fecha_ingreso, beca_porcentaje, registro_incompleto
    ) VALUES (
      v_alumno_id, 'Sofía', 'Demo Google Play', '2021-03-15', 'niña', v_grado_id, v_padre_id,
      true, 12, CURRENT_DATE, 0, false
    );
  ELSE
    UPDATE public.alumnos
    SET padre_id = v_padre_id, grado_id = COALESCE(v_grado_id, grado_id), activo = true
    WHERE id = v_alumno_id;
  END IF;

  INSERT INTO public.alumnos_padres (alumno_id, padre_id, es_principal)
  VALUES (v_alumno_id, v_padre_id, true)
  ON CONFLICT (alumno_id, padre_id) DO UPDATE SET es_principal = true;

  -- ── 5. Pagos demo ─────────────────────────────────────────────────────────
  SELECT id INTO v_pago_pend
  FROM public.pagos
  WHERE alumno_id = v_alumno_id AND concepto ILIKE '%Demo pendiente%'
  LIMIT 1;

  IF v_pago_pend IS NULL THEN
    v_pago_pend := gen_random_uuid();
    INSERT INTO public.pagos (
      id, alumno_id, concepto, mes, monto, monto_pagado, descuento, estatus,
      fecha_vencimiento, tipo_pago, anio_escolar
    ) VALUES (
      v_pago_pend, v_alumno_id,
      'Colegiatura Demo pendiente', 'Marzo 2026', 3500.00, 0, 0, 'pendiente',
      CURRENT_DATE + 15, 'mensualidad', EXTRACT(YEAR FROM CURRENT_DATE)::int
    );
  END IF;

  SELECT id INTO v_pago_ok
  FROM public.pagos
  WHERE alumno_id = v_alumno_id AND concepto ILIKE '%Demo pagada%'
  LIMIT 1;

  IF v_pago_ok IS NULL THEN
    v_pago_ok := gen_random_uuid();
    INSERT INTO public.pagos (
      id, alumno_id, concepto, mes, monto, monto_pagado, descuento, estatus,
      fecha_vencimiento, fecha_pago, forma_pago, tipo_pago, anio_escolar,
      recibido_por_nombre
    ) VALUES (
      v_pago_ok, v_alumno_id,
      'Colegiatura Demo pagada', 'Febrero 2026', 3500.00, 3500.00, 0, 'pagado',
      CURRENT_DATE - 30, CURRENT_DATE - 10, 'Efectivo', 'mensualidad',
      EXTRACT(YEAR FROM CURRENT_DATE)::int, 'Caja CAIPI Demo'
    );
  END IF;

  -- ── 6. Bitácora de hoy ────────────────────────────────────────────────────
  INSERT INTO public.bitacora_diaria (
    id, alumno_id, fecha, comio, pipi, popo, lavo_dientes, tomo_agua,
    respeto_demas, realizo_actividades, siesta, estado_animo, observaciones
  ) VALUES (
    gen_random_uuid(), v_alumno_id, CURRENT_DATE,
    'si', true, true, true, true, true, true, false, 'Feliz',
    'Registro demo para revisores Google Play.'
  )
  ON CONFLICT (alumno_id, fecha) DO UPDATE
    SET comio = EXCLUDED.comio, pipi = EXCLUDED.pipi, popo = EXCLUDED.popo,
        lavo_dientes = EXCLUDED.lavo_dientes, observaciones = EXCLUDED.observaciones,
        updated_at = now();

  -- ── 7. Persona autorizada (recogida) ──────────────────────────────────────
  IF NOT EXISTS (
    SELECT 1 FROM public.personas_autorizadas
    WHERE alumno_id = v_alumno_id AND nombre ILIKE 'Abuela Demo'
  ) THEN
    INSERT INTO public.personas_autorizadas (
      id, alumno_id, nombre, parentesco, telefono, activo
    ) VALUES (
      gen_random_uuid(), v_alumno_id, 'Abuela Demo', 'Abuela', '5550000099', true
    );
  END IF;

  RAISE NOTICE 'Directora demo id: %', v_dir_id;
  RAISE NOTICE 'Padre demo id: %', v_padre_id;
  RAISE NOTICE 'Alumno demo id: %', v_alumno_id;
END $$;

DROP FUNCTION IF EXISTS public._caipi_demo_upsert_auth_user(text, text, text);

-- ── Verificación ────────────────────────────────────────────────────────────
SELECT id, email, rol, nombre, apellidos, activo, acceso_app_modo
FROM public.usuarios
WHERE email IN ('reviwer@caipi.com', 'padre.demo@caipi.com')
ORDER BY rol;

SELECT a.id, a.nombre, a.apellidos, g.nombre AS grado, u.email AS padre
FROM public.alumnos a
LEFT JOIN public.grados g ON g.id = a.grado_id
LEFT JOIN public.usuarios u ON u.id = a.padre_id
WHERE a.nombre ILIKE 'Sofía' AND a.apellidos ILIKE '%Demo%';

SELECT concepto, monto, estatus, fecha_vencimiento
FROM public.pagos p
JOIN public.alumnos a ON a.id = p.alumno_id
WHERE a.nombre ILIKE 'Sofía' AND a.apellidos ILIKE '%Demo%';
