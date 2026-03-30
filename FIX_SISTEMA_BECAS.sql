-- ============================================
-- CAIPI - SISTEMA DE BECAS
-- ============================================
-- Este script agrega:
-- 1. Campo beca_porcentaje en tabla alumnos
-- 2. Actualiza trigger de pagos para aplicar descuento
-- 3. Permite seleccionar beca del 10% al 100%
-- ============================================

-- ============================================
-- 1. AGREGAR CAMPO DE BECA A ALUMNOS
-- ============================================

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'alumnos' AND column_name = 'beca_porcentaje'
  ) THEN
    ALTER TABLE alumnos ADD COLUMN beca_porcentaje INTEGER DEFAULT 0 CHECK (beca_porcentaje >= 0 AND beca_porcentaje <= 100);
    COMMENT ON COLUMN alumnos.beca_porcentaje IS 'Porcentaje de beca (0-100). Ej: 20 = 20% de descuento';
  END IF;
END $$;

-- ============================================
-- 2. ELIMINAR TRIGGER ANTERIOR DE PAGOS
-- ============================================

DROP TRIGGER IF EXISTS trigger_crear_pagos_automaticos ON alumnos;
DROP FUNCTION IF EXISTS crear_pagos_automaticos();

-- ============================================
-- 3. NUEVO TRIGGER CON SISTEMA DE BECAS
-- ============================================

CREATE OR REPLACE FUNCTION crear_pagos_automaticos()
RETURNS TRIGGER AS $$
DECLARE
  v_config configuracion_costos%ROWTYPE;
  v_anio_escolar INTEGER;
  v_mes INTEGER;
  v_monto_mensualidad DECIMAL(10,2);
  v_monto_inscripcion DECIMAL(10,2);
  v_monto_seguro DECIMAL(10,2);
  v_fecha_vencimiento DATE;
  v_numero_pago INTEGER;
  v_factor_descuento DECIMAL(5,4);
BEGIN
  -- Obtener configuración vigente
  SELECT * INTO v_config
  FROM configuracion_costos
  WHERE vigente = true
  ORDER BY vigencia_desde DESC
  LIMIT 1;
  
  -- Si no hay configuración, usar valores por defecto
  IF NOT FOUND THEN
    v_config.costo_inscripcion := 1500.00;
    v_config.costo_seguro_credencial := 300.00;
    v_config.costo_mensualidad_12 := 2000.00;
    v_config.costo_mensualidad_10 := 2400.00;
  END IF;
  
  -- Calcular factor de descuento por beca
  -- Si tiene 20% de beca, el factor es 0.80 (paga el 80%)
  v_factor_descuento := (100 - NEW.beca_porcentaje) / 100.0;
  
  -- Determinar monto de mensualidad según plan
  IF NEW.plan_pagos = 12 THEN
    v_monto_mensualidad := v_config.costo_mensualidad_12 * v_factor_descuento;
  ELSE
    v_monto_mensualidad := v_config.costo_mensualidad_10 * v_factor_descuento;
  END IF;
  
  -- Aplicar descuento a inscripción y seguro
  v_monto_inscripcion := v_config.costo_inscripcion * v_factor_descuento;
  v_monto_seguro := v_config.costo_seguro_credencial * v_factor_descuento;
  
  -- Año escolar actual
  v_anio_escolar := EXTRACT(YEAR FROM NEW.fecha_ingreso);
  
  -- ============================================
  -- PAGO 1: INSCRIPCIÓN ANUAL (con descuento si aplica)
  -- ============================================
  INSERT INTO pagos (
    alumno_id,
    concepto,
    monto,
    fecha_vencimiento,
    anio_escolar,
    estatus,
    tipo_pago,
    notas
  ) VALUES (
    NEW.id,
    'Inscripción Anual ' || v_anio_escolar || 
    CASE 
      WHEN NEW.beca_porcentaje > 0 THEN ' (Beca ' || NEW.beca_porcentaje || '%)'
      ELSE ''
    END,
    v_monto_inscripcion,
    NEW.fecha_ingreso,
    v_anio_escolar,
    'pendiente',
    'inscripcion',
    CASE 
      WHEN NEW.beca_porcentaje > 0 THEN 
        'Beca ' || NEW.beca_porcentaje || '% aplicada. Monto original: $' || v_config.costo_inscripcion
      ELSE NULL
    END
  );
  
  -- ============================================
  -- PAGO 2: SEGURO + CREDENCIAL (con descuento si aplica)
  -- ============================================
  INSERT INTO pagos (
    alumno_id,
    concepto,
    monto,
    fecha_vencimiento,
    anio_escolar,
    estatus,
    tipo_pago,
    notas
  ) VALUES (
    NEW.id,
    'Seguro + Credencial ' || v_anio_escolar ||
    CASE 
      WHEN NEW.beca_porcentaje > 0 THEN ' (Beca ' || NEW.beca_porcentaje || '%)'
      ELSE ''
    END,
    v_monto_seguro,
    NEW.fecha_ingreso,
    v_anio_escolar,
    'pendiente',
    'seguro',
    CASE 
      WHEN NEW.beca_porcentaje > 0 THEN 
        'Beca ' || NEW.beca_porcentaje || '% aplicada. Monto original: $' || v_config.costo_seguro_credencial
      ELSE NULL
    END
  );
  
  -- ============================================
  -- PAGOS 3 a N: MENSUALIDADES (10 o 12)
  -- ============================================
  
  IF NEW.plan_pagos = 12 THEN
    -- PLAN DE 12 MESES (Agosto a Julio)
    FOR v_mes IN 8..12 LOOP
      v_numero_pago := v_mes - 7;
      v_fecha_vencimiento := DATE(v_anio_escolar || '-' || LPAD(v_mes::TEXT, 2, '0') || '-05');
      
      INSERT INTO pagos (
        alumno_id,
        concepto,
        monto,
        fecha_vencimiento,
        anio_escolar,
        estatus,
        tipo_pago,
        notas
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/12)' ||
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN ' - Beca ' || NEW.beca_porcentaje || '%'
          ELSE ''
        END,
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad',
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN 
            'Beca ' || NEW.beca_porcentaje || '% aplicada. Monto original: $' || v_config.costo_mensualidad_12
          ELSE NULL
        END
      );
    END LOOP;
    
    -- Enero a Julio del siguiente año
    FOR v_mes IN 1..7 LOOP
      v_numero_pago := v_mes + 5;
      v_fecha_vencimiento := DATE((v_anio_escolar + 1) || '-' || LPAD(v_mes::TEXT, 2, '0') || '-05');
      
      INSERT INTO pagos (
        alumno_id,
        concepto,
        monto,
        fecha_vencimiento,
        anio_escolar,
        estatus,
        tipo_pago,
        notas
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/12)' ||
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN ' - Beca ' || NEW.beca_porcentaje || '%'
          ELSE ''
        END,
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad',
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN 
            'Beca ' || NEW.beca_porcentaje || '% aplicada. Monto original: $' || v_config.costo_mensualidad_12
          ELSE NULL
        END
      );
    END LOOP;
    
  ELSE
    -- PLAN DE 10 MESES (Agosto a Mayo)
    FOR v_mes IN 8..12 LOOP
      v_numero_pago := v_mes - 7;
      v_fecha_vencimiento := DATE(v_anio_escolar || '-' || LPAD(v_mes::TEXT, 2, '0') || '-05');
      
      INSERT INTO pagos (
        alumno_id,
        concepto,
        monto,
        fecha_vencimiento,
        anio_escolar,
        estatus,
        tipo_pago,
        notas
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/10)' ||
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN ' - Beca ' || NEW.beca_porcentaje || '%'
          ELSE ''
        END,
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad',
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN 
            'Beca ' || NEW.beca_porcentaje || '% aplicada. Monto original: $' || v_config.costo_mensualidad_10
          ELSE NULL
        END
      );
    END LOOP;
    
    -- Enero a Mayo del siguiente año
    FOR v_mes IN 1..5 LOOP
      v_numero_pago := v_mes + 5;
      v_fecha_vencimiento := DATE((v_anio_escolar + 1) || '-' || LPAD(v_mes::TEXT, 2, '0') || '-05');
      
      INSERT INTO pagos (
        alumno_id,
        concepto,
        monto,
        fecha_vencimiento,
        anio_escolar,
        estatus,
        tipo_pago,
        notas
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/10)' ||
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN ' - Beca ' || NEW.beca_porcentaje || '%'
          ELSE ''
        END,
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad',
        CASE 
          WHEN NEW.beca_porcentaje > 0 THEN 
            'Beca ' || NEW.beca_porcentaje || '% aplicada. Monto original: $' || v_config.costo_mensualidad_10
          ELSE NULL
        END
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger
CREATE TRIGGER trigger_crear_pagos_automaticos
  AFTER INSERT ON alumnos
  FOR EACH ROW
  EXECUTE FUNCTION crear_pagos_automaticos();

-- ============================================
-- 4. VISTA: Alumnos con Becas
-- ============================================

CREATE OR REPLACE VIEW vista_alumnos_con_becas AS
SELECT 
  a.id,
  a.nombre || ' ' || a.apellidos AS nombre_completo,
  a.beca_porcentaje,
  g.nombre AS grado,
  COUNT(p.id) AS total_pagos,
  SUM(p.monto) AS total_a_pagar,
  SUM(p.monto_pagado) AS total_pagado,
  SUM(p.monto - p.monto_pagado) AS total_pendiente
FROM alumnos a
LEFT JOIN grados g ON a.grado_id = g.id
LEFT JOIN pagos p ON a.id = p.alumno_id
WHERE a.beca_porcentaje > 0
  AND a.activo = true
GROUP BY a.id, a.nombre, a.apellidos, a.beca_porcentaje, g.nombre
ORDER BY a.beca_porcentaje DESC, a.nombre;

-- ============================================
-- ✅ LISTO - EJECUTAR EN SUPABASE
-- ============================================

/*
FUNCIONALIDADES AGREGADAS:

1. ✅ Campo beca_porcentaje en tabla alumnos (0-100)
2. ✅ Al crear alumno, los pagos se generan con descuento automático
3. ✅ El descuento se aplica a:
   - Inscripción
   - Seguro + Credencial
   - Todas las mensualidades
4. ✅ En el concepto se indica la beca (ej: "Mensualidad Marzo - Beca 20%")
5. ✅ En notas se guarda el monto original sin descuento
6. ✅ Vista para consultar alumnos con becas

EJEMPLOS:

-- Alumno con beca del 20%
-- Mensualidad normal: $2,000
-- Mensualidad con beca: $1,600 (ahorra $400)

-- Alumno con beca del 50%
-- Mensualidad normal: $2,000
-- Mensualidad con beca: $1,000 (ahorra $1,000)

-- Alumno con beca del 100% (beca completa)
-- Mensualidad normal: $2,000
-- Mensualidad con beca: $0 (gratis)

CONSULTAS ÚTILES:

-- Ver alumnos con becas
SELECT * FROM vista_alumnos_con_becas;

-- Ver total de becas otorgadas
SELECT 
  COUNT(*) AS alumnos_con_beca,
  AVG(beca_porcentaje) AS promedio_beca,
  SUM(total_pendiente) AS total_a_recaudar
FROM vista_alumnos_con_becas;
*/
