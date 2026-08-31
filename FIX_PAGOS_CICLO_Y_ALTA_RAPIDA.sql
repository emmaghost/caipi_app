-- =============================================================================
-- FIX: ciclo escolar de pagos + no crear meses anteriores al ingreso
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================
-- Problema: al dar de alta un niño, meses futuros salían como "adeudo/vencido"
-- porque el trigger usaba mal el año del ciclo o generaba meses ya pasados.
-- =============================================================================

ALTER TABLE public.alumnos
  ADD COLUMN IF NOT EXISTS registro_incompleto BOOLEAN NOT NULL DEFAULT false;

DROP TRIGGER IF EXISTS trigger_crear_pagos_automaticos ON public.alumnos;
DROP TRIGGER IF EXISTS trg_generar_pagos_alumno ON public.alumnos;
DROP FUNCTION IF EXISTS crear_pagos_automaticos();
DROP FUNCTION IF EXISTS generar_pagos_alumno();

CREATE OR REPLACE FUNCTION public.crear_pagos_automaticos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_config configuracion_costos%ROWTYPE;
  v_anio_ciclo INTEGER;
  v_mes INTEGER;
  v_monto_mensualidad NUMERIC(10,2);
  v_monto_inscripcion NUMERIC(10,2);
  v_monto_seguro NUMERIC(10,2);
  v_fecha_vencimiento DATE;
  v_factor NUMERIC(5,4);
  v_desde DATE;
  v_ultimo_mes INTEGER;
BEGIN
  -- Si la app Flutter ya insertó pagos, no duplicar
  IF EXISTS (SELECT 1 FROM pagos WHERE alumno_id = NEW.id LIMIT 1) THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_config
  FROM configuracion_costos
  WHERE vigente = true
  ORDER BY vigencia_desde DESC
  LIMIT 1;

  IF NOT FOUND THEN
    v_config.costo_inscripcion := 2000;
    v_config.costo_seguro_credencial := 500;
    v_config.costo_mensualidad_12 := 1500;
    v_config.costo_mensualidad_10 := 2400;
  END IF;

  v_factor := (100 - COALESCE(NEW.beca_porcentaje, 0)) / 100.0;

  IF COALESCE(NEW.plan_pagos, 12) = 10 THEN
    v_monto_mensualidad := v_config.costo_mensualidad_10 * v_factor;
    v_ultimo_mes := 5; -- Ago–May
  ELSE
    v_monto_mensualidad := v_config.costo_mensualidad_12 * v_factor;
    v_ultimo_mes := 7; -- Ago–Jul
  END IF;

  v_monto_inscripcion := v_config.costo_inscripcion * v_factor;
  v_monto_seguro := v_config.costo_seguro_credencial * v_factor;

  -- Ciclo: ago–dic año N, ene–jul año N+1
  IF EXTRACT(MONTH FROM NEW.fecha_ingreso) >= 8 THEN
    v_anio_ciclo := EXTRACT(YEAR FROM NEW.fecha_ingreso)::INT;
  ELSE
    v_anio_ciclo := EXTRACT(YEAR FROM NEW.fecha_ingreso)::INT - 1;
  END IF;

  v_desde := date_trunc('month', NEW.fecha_ingreso)::DATE;

  INSERT INTO pagos (
    alumno_id, concepto, mes, monto, monto_pagado, fecha_vencimiento,
    anio_escolar, estatus, tipo_pago
  ) VALUES (
    NEW.id,
    'Inscripción Anual',
    'Inscripción ' || v_anio_ciclo,
    v_monto_inscripcion,
    0,
    (NEW.fecha_ingreso + INTERVAL '15 days')::DATE,
    v_anio_ciclo,
    'pendiente',
    'inscripcion'
  );

  INSERT INTO pagos (
    alumno_id, concepto, mes, monto, monto_pagado, fecha_vencimiento,
    anio_escolar, estatus, tipo_pago
  ) VALUES (
    NEW.id,
    'Seguro y Credencial',
    'Seguro ' || v_anio_ciclo,
    v_monto_seguro,
    0,
    (NEW.fecha_ingreso + INTERVAL '15 days')::DATE,
    v_anio_ciclo,
    'pendiente',
    'seguro'
  );

  FOR v_mes IN 8..12 LOOP
    v_fecha_vencimiento := make_date(v_anio_ciclo, v_mes, 5);
    IF date_trunc('month', v_fecha_vencimiento)::DATE >= v_desde THEN
      INSERT INTO pagos (
        alumno_id, concepto, mes, monto, monto_pagado, fecha_vencimiento,
        anio_escolar, estatus, tipo_pago
      ) VALUES (
        NEW.id,
        'Colegiatura',
        to_char(v_fecha_vencimiento, 'TMMonth YYYY'),
        v_monto_mensualidad,
        0,
        v_fecha_vencimiento,
        v_anio_ciclo,
        'pendiente',
        'mensualidad'
      );
    END IF;
  END LOOP;

  FOR v_mes IN 1..v_ultimo_mes LOOP
    v_fecha_vencimiento := make_date(v_anio_ciclo + 1, v_mes, 5);
    IF date_trunc('month', v_fecha_vencimiento)::DATE >= v_desde THEN
      INSERT INTO pagos (
        alumno_id, concepto, mes, monto, monto_pagado, fecha_vencimiento,
        anio_escolar, estatus, tipo_pago
      ) VALUES (
        NEW.id,
        'Colegiatura',
        to_char(v_fecha_vencimiento, 'TMMonth YYYY'),
        v_monto_mensualidad,
        0,
        v_fecha_vencimiento,
        v_anio_ciclo,
        'pendiente',
        'mensualidad'
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_crear_pagos_automaticos ON public.alumnos;
CREATE TRIGGER trigger_crear_pagos_automaticos
  AFTER INSERT ON public.alumnos
  FOR EACH ROW
  EXECUTE FUNCTION public.crear_pagos_automaticos();

-- Rol secretaria (crear/editar alumnos) + asegurar permisos a profesor_admin
INSERT INTO roles (codigo, nombre, descripcion, nivel_jerarquia)
VALUES (
  'secretaria',
  'Secretaria',
  'Alta y edición de alumnos (datos incompletos / completar después)',
  2
)
ON CONFLICT (codigo) DO NOTHING;

-- En esta BD la columna es "clave" (no "codigo" / "tipo")
INSERT INTO permisos (clave, nombre, descripcion, modulo)
VALUES
  ('ver_alumnos', 'Ver Alumnos', 'Ver lista de alumnos', 'alumnos'),
  ('crear_alumno', 'Crear Alumno', 'Registrar nuevo alumno', 'alumnos'),
  ('editar_alumno', 'Editar Alumno', 'Modificar información del alumno', 'alumnos')
ON CONFLICT (clave) DO NOTHING;

INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permisos p
WHERE r.codigo IN ('secretaria', 'profesor_admin', 'directora')
  AND p.clave IN ('ver_alumnos', 'crear_alumno', 'editar_alumno')
ON CONFLICT DO NOTHING;

COMMENT ON COLUMN public.alumnos.registro_incompleto IS
  'true = alta rápida; falta completar datos (padre, emergencia, etc.)';

-- Ampliar RLS de alumnos para secretaria (mismo acceso que profesor_admin en altas)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'alumnos' AND policyname = 'alumnos_insert_directora_admin'
  ) THEN
    EXECUTE $p$
      DROP POLICY IF EXISTS alumnos_insert_directora_admin ON public.alumnos;
      CREATE POLICY alumnos_insert_directora_admin ON public.alumnos
        FOR INSERT TO authenticated
        WITH CHECK (
          EXISTS (
            SELECT 1 FROM public.usuarios
            WHERE id = auth.uid()
              AND rol IN ('directora', 'profesor_admin', 'secretaria')
          )
        );
    $p$;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'alumnos' AND policyname = 'alumnos_update_directora_admin'
  ) THEN
    EXECUTE $p$
      DROP POLICY IF EXISTS alumnos_update_directora_admin ON public.alumnos;
      CREATE POLICY alumnos_update_directora_admin ON public.alumnos
        FOR UPDATE TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM public.usuarios
            WHERE id = auth.uid()
              AND rol IN ('directora', 'profesor_admin', 'secretaria')
          )
        )
        WITH CHECK (
          EXISTS (
            SELECT 1 FROM public.usuarios
            WHERE id = auth.uid()
              AND rol IN ('directora', 'profesor_admin', 'secretaria')
          )
        );
    $p$;
  END IF;
END $$;
