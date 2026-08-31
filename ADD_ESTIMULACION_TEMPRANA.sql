-- =============================================================================
-- Estimulación temprana + grado opcional en alta
-- Ejecutar en Supabase → SQL Editor (una sola base)
-- =============================================================================

-- Grado Estimulación Temprana
INSERT INTO public.grados (nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo)
SELECT
  'Estimulación Temprana',
  'Bebés / estimulación (planes por sesión o paquetes)',
  0,
  2,
  20,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.grados WHERE lower(nombre) LIKE '%estimul%'
);

-- Plan de estimulación en alumnos
ALTER TABLE public.alumnos
  ADD COLUMN IF NOT EXISTS plan_estimulacion TEXT;

COMMENT ON COLUMN public.alumnos.plan_estimulacion IS
  'sesion | paquete_4 | paquete_6 | paquete_8. Solo aplica si el grado es Estimulación.';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'alumnos_plan_estimulacion_check'
  ) THEN
    ALTER TABLE public.alumnos
      ADD CONSTRAINT alumnos_plan_estimulacion_check
      CHECK (
        plan_estimulacion IS NULL
        OR plan_estimulacion IN ('sesion', 'paquete_4', 'paquete_6', 'paquete_8')
      );
  END IF;
END $$;

-- Costos estimulación en configuracion_costos
ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS estim_sesion NUMERIC(10,2) DEFAULT 350;
ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS estim_paquete_4 NUMERIC(10,2) DEFAULT 950;
ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS estim_paquete_6 NUMERIC(10,2) DEFAULT 1100;
ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS estim_paquete_8 NUMERIC(10,2) DEFAULT 1150;
ALTER TABLE public.configuracion_costos
  ADD COLUMN IF NOT EXISTS estim_inscripcion_anual NUMERIC(10,2) DEFAULT 1150;

UPDATE public.configuracion_costos
SET
  estim_sesion = COALESCE(estim_sesion, 350),
  estim_paquete_4 = COALESCE(estim_paquete_4, 950),
  estim_paquete_6 = COALESCE(estim_paquete_6, 1100),
  estim_paquete_8 = COALESCE(estim_paquete_8, 1150),
  estim_inscripcion_anual = COALESCE(estim_inscripcion_anual, 1150);

-- Trigger: no generar colegiaturas de kínder si es estimulación
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
  -- Estimulación la genera la app (sesión/paquetes + inscripción).
  IF NEW.plan_estimulacion IS NOT NULL AND NEW.plan_estimulacion <> '' THEN
    RETURN NEW;
  END IF;

  -- Sin grado o maternal: cobro por clase → no colegiaturas automáticas.
  IF NEW.grado_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.grados g
    WHERE g.id = NEW.grado_id
      AND (
        lower(g.nombre) LIKE '%maternal%'
        OR (
          lower(g.nombre) NOT LIKE '%kinder%'
          AND lower(g.nombre) NOT LIKE '%kínder%'
          AND lower(g.nombre) NOT LIKE '%estimul%'
        )
      )
  ) THEN
    RETURN NEW;
  END IF;

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
    v_ultimo_mes := 5;
  ELSIF v_plan = 11 THEN
    v_monto_mensualidad := COALESCE(v_config.costo_mensualidad_11, 2200) * v_factor;
    v_ultimo_mes := 6;
  ELSE
    v_monto_mensualidad := v_config.costo_mensualidad_12 * v_factor;
    v_ultimo_mes := 7;
  END IF;

  IF EXTRACT(MONTH FROM NEW.fecha_ingreso) >= 8 THEN
    v_anio_ciclo := EXTRACT(YEAR FROM NEW.fecha_ingreso)::INT;
  ELSE
    v_anio_ciclo := EXTRACT(YEAR FROM NEW.fecha_ingreso)::INT - 1;
  END IF;

  v_desde := date_trunc('month', NEW.fecha_ingreso)::DATE;

  FOR v_mes IN 8..12 LOOP
    v_fecha_vencimiento := make_date(v_anio_ciclo, v_mes, 5);
    IF date_trunc('month', v_fecha_vencimiento)::DATE >= v_desde THEN
      INSERT INTO pagos (
        alumno_id, concepto, mes, monto, monto_pagado, fecha_vencimiento,
        anio_escolar, estatus, tipo_pago
      ) VALUES (
        NEW.id, 'Colegiatura', to_char(v_fecha_vencimiento, 'TMMonth YYYY'),
        v_monto_mensualidad, 0, v_fecha_vencimiento, v_anio_ciclo,
        'pendiente', 'mensualidad'
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
        NEW.id, 'Colegiatura', to_char(v_fecha_vencimiento, 'TMMonth YYYY'),
        v_monto_mensualidad, 0, v_fecha_vencimiento, v_anio_ciclo,
        'pendiente', 'mensualidad'
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

