-- =============================================================================
-- Plan 11 meses + cuadro de pagos solo colegiaturas
-- Ejecutar en Supabase → SQL Editor
-- NO borra alumnos ni abonos; solo ajusta schema/trigger y oculta cargos viejos
-- de inscripción/seguro del flujo automático.
-- =============================================================================

-- 1) Costo mensualidad plan 11
ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS costo_mensualidad_11 NUMERIC(10,2);

UPDATE public.configuracion_costos
SET costo_mensualidad_11 = ROUND(
  (COALESCE(costo_mensualidad_12, 1500) + COALESCE(costo_mensualidad_10, 2400)) / 2,
  2
)
WHERE costo_mensualidad_11 IS NULL;

ALTER TABLE public.configuracion_costos
  ALTER COLUMN costo_mensualidad_11 SET DEFAULT 2200.00;

ALTER TABLE public.configuracion_costos
  ALTER COLUMN costo_mensualidad_11 SET NOT NULL;

COMMENT ON COLUMN public.configuracion_costos.costo_mensualidad_11 IS
  'Cuota mensual del plan 11 meses (Agosto–Junio)';

-- 2) Permitir plan_pagos = 11
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT c.conname
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'alumnos'
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) ILIKE '%plan_pagos%'
  LOOP
    EXECUTE format('ALTER TABLE public.alumnos DROP CONSTRAINT %I', r.conname);
  END LOOP;
END $$;

ALTER TABLE public.alumnos
  ADD CONSTRAINT alumnos_plan_pagos_check
  CHECK (plan_pagos IN (10, 11, 12));

COMMENT ON COLUMN public.alumnos.plan_pagos IS
  'Plan de pagos: 10 (Ago–May), 11 (Ago–Jun) o 12 (Ago–Jul) mensualidades';

-- 3) Trigger: solo colegiaturas (sin inscripción ni seguro)
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
  v_fecha_vencimiento DATE;
  v_factor NUMERIC(5,4);
  v_desde DATE;
  v_ultimo_mes INTEGER;
  v_plan INTEGER;
BEGIN
  IF EXISTS (SELECT 1 FROM pagos WHERE alumno_id = NEW.id LIMIT 1) THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_config
  FROM configuracion_costos
  WHERE vigente = true
  ORDER BY vigencia_desde DESC
  LIMIT 1;

  IF NOT FOUND THEN
    v_config.costo_mensualidad_12 := 1500;
    v_config.costo_mensualidad_11 := 2200;
    v_config.costo_mensualidad_10 := 2400;
  END IF;

  v_factor := (100 - COALESCE(NEW.beca_porcentaje, 0)) / 100.0;
  v_plan := COALESCE(NEW.plan_pagos, 12);

  IF v_plan = 10 THEN
    v_monto_mensualidad := v_config.costo_mensualidad_10 * v_factor;
    v_ultimo_mes := 5; -- Ago–May
  ELSIF v_plan = 11 THEN
    v_monto_mensualidad := COALESCE(v_config.costo_mensualidad_11, 2200) * v_factor;
    v_ultimo_mes := 6; -- Ago–Jun
  ELSE
    v_monto_mensualidad := v_config.costo_mensualidad_12 * v_factor;
    v_ultimo_mes := 7; -- Ago–Jul
  END IF;

  IF EXTRACT(MONTH FROM NEW.fecha_ingreso) >= 8 THEN
    v_anio_ciclo := EXTRACT(YEAR FROM NEW.fecha_ingreso)::INT;
  ELSE
    v_anio_ciclo := EXTRACT(YEAR FROM NEW.fecha_ingreso)::INT - 1;
  END IF;

  v_desde := date_trunc('month', NEW.fecha_ingreso)::DATE;

  -- Solo colegiaturas: inscripción/seguro NO se insertan en pagos
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

CREATE TRIGGER trigger_crear_pagos_automaticos
  AFTER INSERT ON public.alumnos
  FOR EACH ROW
  EXECUTE FUNCTION public.crear_pagos_automaticos();
