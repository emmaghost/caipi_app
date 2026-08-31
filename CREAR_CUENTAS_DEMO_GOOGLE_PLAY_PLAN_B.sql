-- =============================================================================
-- PLAN B — Perfiles demo SIN tocar auth.users
-- Usar si el script principal falla con gen_salt/crypt.
--
-- PASO 1 (manual en Supabase):
--   Authentication → Users → Add user → Create new user
--   A) reviwer@caipi.com     / reviwer2026Caipi  (Auto confirm ✅)
--   B) padre.demo@caipi.com  / reviwer2026Caipi  (Auto confirm ✅)
--
-- PASO 2: Ejecutar ESTE SQL en SQL Editor
-- =============================================================================

DO $$
DECLARE
  v_dir_id uuid;
  v_padre_id uuid;
  v_alumno_id uuid;
  v_grado_id uuid;
BEGIN
  SELECT id INTO v_dir_id FROM auth.users WHERE lower(email) = 'reviwer@caipi.com';
  SELECT id INTO v_padre_id FROM auth.users WHERE lower(email) = 'padre.demo@caipi.com';

  IF v_dir_id IS NULL THEN
    RAISE EXCEPTION 'Falta crear reviwer@caipi.com en Authentication → Users';
  END IF;
  IF v_padre_id IS NULL THEN
    RAISE EXCEPTION 'Falta crear padre.demo@caipi.com en Authentication → Users';
  END IF;

  INSERT INTO public.usuarios (id, email, nombre, apellidos, rol, activo)
  VALUES (v_dir_id, 'reviwer@caipi.com', 'Google Play', 'Reviewer', 'directora', true)
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, nombre = EXCLUDED.nombre, apellidos = EXCLUDED.apellidos,
        rol = 'directora', activo = true;

  INSERT INTO public.usuarios (
    id, email, nombre, apellidos, telefono, whatsapp, rol, activo, acceso_app_modo
  ) VALUES (
    v_padre_id, 'padre.demo@caipi.com', 'Carlos', 'Demo Padre',
    '5550000001', '5550000001', 'padre', true, 'desbloqueado'
  )
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, nombre = EXCLUDED.nombre, apellidos = EXCLUDED.apellidos,
        telefono = EXCLUDED.telefono, whatsapp = EXCLUDED.whatsapp,
        rol = 'padre', activo = true, acceso_app_modo = 'desbloqueado';

  UPDATE public.usuarios
  SET qr_permanente = COALESCE(qr_permanente, 'QR-PADRE-DEMO-' || left(v_padre_id::text, 8))
  WHERE id = v_padre_id;

  SELECT id INTO v_grado_id
  FROM public.grados
  WHERE activo = true AND nombre ILIKE '%kinder 1%'
  LIMIT 1;
  IF v_grado_id IS NULL THEN
    SELECT id INTO v_grado_id FROM public.grados WHERE activo = true ORDER BY nombre LIMIT 1;
  END IF;

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

  IF NOT EXISTS (
    SELECT 1 FROM public.pagos
    WHERE alumno_id = v_alumno_id AND concepto ILIKE '%Demo pendiente%'
  ) THEN
    INSERT INTO public.pagos (
      id, alumno_id, concepto, mes, monto, monto_pagado, descuento, estatus,
      fecha_vencimiento, tipo_pago, anio_escolar
    ) VALUES (
      gen_random_uuid(), v_alumno_id,
      'Colegiatura Demo pendiente', 'Marzo 2026', 3500.00, 0, 0, 'pendiente',
      CURRENT_DATE + 15, 'mensualidad', EXTRACT(YEAR FROM CURRENT_DATE)::int
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.pagos
    WHERE alumno_id = v_alumno_id AND concepto ILIKE '%Demo pagada%'
  ) THEN
    INSERT INTO public.pagos (
      id, alumno_id, concepto, mes, monto, monto_pagado, descuento, estatus,
      fecha_vencimiento, fecha_pago, forma_pago, tipo_pago, anio_escolar,
      recibido_por_nombre
    ) VALUES (
      gen_random_uuid(), v_alumno_id,
      'Colegiatura Demo pagada', 'Febrero 2026', 3500.00, 3500.00, 0, 'pagado',
      CURRENT_DATE - 30, CURRENT_DATE - 10, 'Efectivo', 'mensualidad',
      EXTRACT(YEAR FROM CURRENT_DATE)::int, 'Caja CAIPI Demo'
    );
  END IF;

  INSERT INTO public.bitacora_diaria (
    id, alumno_id, fecha, comio, pipi, popo, lavo_dientes, tomo_agua,
    respeto_demas, realizo_actividades, siesta, estado_animo, observaciones
  ) VALUES (
    gen_random_uuid(), v_alumno_id, CURRENT_DATE,
    'si', true, true, true, true, true, true, false, 'Feliz',
    'Registro demo para revisores Google Play.'
  )
  ON CONFLICT (alumno_id, fecha) DO UPDATE
    SET observaciones = EXCLUDED.observaciones, updated_at = now();

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
END $$;

SELECT id, email, rol, nombre, activo FROM public.usuarios
WHERE email IN ('reviwer@caipi.com', 'padre.demo@caipi.com');
