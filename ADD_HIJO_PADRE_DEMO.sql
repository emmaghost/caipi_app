-- =============================================================================
-- Agregar hijo demo al padre Google Play
-- Email padre: padre.demo@caipi.com
-- Hija: Sofía Demo Google Play (+ 2 pagos + bitácora + abuela)
-- Ejecutar en Supabase → SQL Editor → Run
-- =============================================================================

DO $$
DECLARE
  v_padre_id uuid;
  v_alumno_id uuid;
  v_grado_id uuid;
BEGIN
  SELECT id INTO v_padre_id
  FROM public.usuarios
  WHERE lower(email) = 'padre.demo@caipi.com' AND rol = 'padre'
  LIMIT 1;

  IF v_padre_id IS NULL THEN
    SELECT id INTO v_padre_id
    FROM auth.users
    WHERE lower(email) = 'padre.demo@caipi.com'
    LIMIT 1;
  END IF;

  IF v_padre_id IS NULL THEN
    RAISE EXCEPTION 'No existe padre.demo@caipi.com. Crea primero la cuenta demo.';
  END IF;

  -- Asegurar perfil padre
  INSERT INTO public.usuarios (
    id, email, nombre, apellidos, telefono, whatsapp, rol, activo, acceso_app_modo
  ) VALUES (
    v_padre_id, 'padre.demo@caipi.com', 'Carlos', 'Demo Padre',
    '5550000001', '5550000001', 'padre', true, 'desbloqueado'
  )
  ON CONFLICT (id) DO UPDATE
    SET rol = 'padre', activo = true, acceso_app_modo = 'desbloqueado';

  UPDATE public.usuarios
  SET qr_permanente = COALESCE(qr_permanente, 'QR-PADRE-DEMO-' || left(v_padre_id::text, 8))
  WHERE id = v_padre_id;

  SELECT id INTO v_grado_id
  FROM public.grados
  WHERE activo = true AND nombre ILIKE '%kinder 1%'
  ORDER BY nombre
  LIMIT 1;

  IF v_grado_id IS NULL THEN
    SELECT id INTO v_grado_id
    FROM public.grados
    WHERE activo = true
    ORDER BY nombre
    LIMIT 1;
  END IF;

  IF v_grado_id IS NULL THEN
    RAISE EXCEPTION 'No hay grados activos. Crea un grado (ej. Kinder 1) primero.';
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
    SET padre_id = v_padre_id,
        grado_id = COALESCE(v_grado_id, grado_id),
        activo = true
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

  RAISE NOTICE 'OK — Padre: % | Alumna: Sofía Demo Google Play (%)', v_padre_id, v_alumno_id;
END $$;

-- Verificación
SELECT u.email AS padre, a.nombre, a.apellidos, g.nombre AS grado, a.activo
FROM public.alumnos a
JOIN public.usuarios u ON u.id = a.padre_id
LEFT JOIN public.grados g ON g.id = a.grado_id
WHERE lower(u.email) = 'padre.demo@caipi.com';
