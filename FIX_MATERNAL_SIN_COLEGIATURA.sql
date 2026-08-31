-- Maternal / estimulación: NO generar colegiaturas de kínder.
-- Estimulación temprana = maternal (se oculta el grado duplicado).
-- Ejecutar en Supabase → SQL Editor. No borra pagos ya cobrados.

-- 1) Trigger: solo kínder genera colegiaturas automáticas
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
  v_nombre TEXT;
BEGIN
  IF NEW.grado_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT lower(g.nombre) INTO v_nombre
  FROM public.grados g
  WHERE g.id = NEW.grado_id;

  -- Solo kínder. Maternal, estimulación, sin asignar, etc. → cobro por clase.
  IF v_nombre IS NULL
     OR (
       v_nombre NOT LIKE '%kinder%'
       AND v_nombre NOT LIKE '%kínder%'
     ) THEN
    RETURN NEW;
  END IF;

  IF EXISTS (SELECT 1 FROM public.pagos WHERE alumno_id = NEW.id LIMIT 1) THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_config
  FROM public.configuracion_costos
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
      INSERT INTO public.pagos (
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
      INSERT INTO public.pagos (
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

-- 2) Pasar alumnos de "Estimulación" a Maternal (si existe)
UPDATE public.alumnos a
SET grado_id = m.id
FROM public.grados e
JOIN public.grados m
  ON lower(m.nombre) LIKE '%maternal%'
 AND m.activo IS DISTINCT FROM false
WHERE a.grado_id = e.id
  AND lower(e.nombre) LIKE '%estimul%';

UPDATE public.grados
SET activo = false
WHERE lower(nombre) LIKE '%estimul%';

-- 3) Quitar colegiaturas automáticas NO cobradas de niños que no son kínder
--    (el caso del maternal que recibió meses de kínder).
DELETE FROM public.pagos p
WHERE COALESCE(p.tipo_pago, '') IN ('mensualidad', '')
  AND COALESCE(p.monto_pagado, 0) = 0
  AND COALESCE(p.estatus, 'pendiente') IN ('pendiente', 'vencido')
  AND (
    p.concepto ILIKE '%colegiatura%'
    OR p.tipo_pago = 'mensualidad'
  )
  AND EXISTS (
    SELECT 1
    FROM public.alumnos a
    LEFT JOIN public.grados g ON g.id = a.grado_id
    WHERE a.id = p.alumno_id
      AND (
        a.grado_id IS NULL
        OR (
          lower(COALESCE(g.nombre, '')) NOT LIKE '%kinder%'
          AND lower(COALESCE(g.nombre, '')) NOT LIKE '%kínder%'
        )
      )
  );

-- Asegura el trigger (por si hay un nombre viejo apuntando a otra función)
DROP TRIGGER IF EXISTS trigger_generar_pagos_alumno ON public.alumnos;
DROP TRIGGER IF EXISTS trg_generar_pagos_alumno ON public.alumnos;

DROP TRIGGER IF EXISTS trigger_crear_pagos_automaticos ON public.alumnos;
CREATE TRIGGER trigger_crear_pagos_automaticos
  AFTER INSERT ON public.alumnos
  FOR EACH ROW
  EXECUTE FUNCTION public.crear_pagos_automaticos();

NOTIFY pgrst, 'reload schema';
