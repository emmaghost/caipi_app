-- ============================================
-- CAIPI - PLANES DE PAGO Y CONFIGURACIÓN
-- ============================================
-- Ejecutar DESPUÉS de SQL_MAESTRO_COMPLETO.sql
-- Este script agrega:
-- 1. Tabla de configuración de costos
-- 2. Campo plan_pagos en alumnos
-- 3. Nuevo trigger para pagos según plan
-- ============================================

-- ============================================
-- 1. TABLA DE CONFIGURACIÓN DE COSTOS
-- ============================================

CREATE TABLE IF NOT EXISTS configuracion_costos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- COSTOS
  costo_inscripcion DECIMAL(10,2) NOT NULL DEFAULT 1500.00,
  costo_seguro_credencial DECIMAL(10,2) NOT NULL DEFAULT 300.00,
  costo_mensualidad_12 DECIMAL(10,2) NOT NULL DEFAULT 2000.00,
  costo_mensualidad_10 DECIMAL(10,2) NOT NULL DEFAULT 2400.00,
  
  -- METADATA
  vigente BOOLEAN NOT NULL DEFAULT true,
  vigencia_desde DATE NOT NULL DEFAULT CURRENT_DATE,
  vigencia_hasta DATE,
  notas TEXT,
  
  -- AUDITORÍA
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES usuarios(id),
  updated_by UUID REFERENCES usuarios(id)
);

-- Índice para búsquedas rápidas
CREATE INDEX idx_config_costos_vigente ON configuracion_costos(vigente, vigencia_desde DESC);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION actualizar_updated_at_config_costos()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_updated_at_config_costos
  BEFORE UPDATE ON configuracion_costos
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at_config_costos();

-- Insertar configuración inicial
INSERT INTO configuracion_costos (
  costo_inscripcion,
  costo_seguro_credencial,
  costo_mensualidad_12,
  costo_mensualidad_10,
  vigente,
  notas
) VALUES (
  1500.00,
  300.00,
  2000.00,
  2400.00,
  true,
  'Configuración inicial de costos 2026'
) ON CONFLICT DO NOTHING;

-- ============================================
-- 2. AGREGAR PLAN DE PAGOS A ALUMNOS
-- ============================================

-- Agregar columna si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'alumnos' AND column_name = 'plan_pagos'
  ) THEN
    ALTER TABLE alumnos ADD COLUMN plan_pagos INTEGER NOT NULL DEFAULT 12 CHECK (plan_pagos IN (10, 12));
    COMMENT ON COLUMN alumnos.plan_pagos IS 'Plan de pagos: 10 o 12 mensualidades';
  END IF;
END $$;

-- ============================================
-- 3. ELIMINAR TRIGGER ANTERIOR DE PAGOS
-- ============================================

DROP TRIGGER IF EXISTS trigger_crear_pagos_automaticos ON alumnos;
DROP FUNCTION IF EXISTS crear_pagos_automaticos();

-- ============================================
-- 4. NUEVO TRIGGER PARA PAGOS SEGÚN PLAN
-- ============================================

CREATE OR REPLACE FUNCTION crear_pagos_automaticos()
RETURNS TRIGGER AS $$
DECLARE
  v_config configuracion_costos%ROWTYPE;
  v_anio_escolar INTEGER;
  v_mes INTEGER;
  v_monto_mensualidad DECIMAL(10,2);
  v_fecha_vencimiento DATE;
  v_numero_pago INTEGER;
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
  
  -- Determinar monto según plan
  IF NEW.plan_pagos = 12 THEN
    v_monto_mensualidad := v_config.costo_mensualidad_12;
  ELSE
    v_monto_mensualidad := v_config.costo_mensualidad_10;
  END IF;
  
  -- Año escolar actual
  v_anio_escolar := EXTRACT(YEAR FROM NEW.fecha_ingreso);
  
  -- ============================================
  -- PAGO 1: INSCRIPCIÓN ANUAL
  -- ============================================
  INSERT INTO pagos (
    alumno_id,
    concepto,
    monto,
    fecha_vencimiento,
    anio_escolar,
    estatus,
    tipo_pago
  ) VALUES (
    NEW.id,
    'Inscripción Anual ' || v_anio_escolar,
    v_config.costo_inscripcion,
    NEW.fecha_ingreso,
    v_anio_escolar,
    'pendiente',
    'inscripcion'
  );
  
  -- ============================================
  -- PAGO 2: SEGURO + CREDENCIAL
  -- ============================================
  INSERT INTO pagos (
    alumno_id,
    concepto,
    monto,
    fecha_vencimiento,
    anio_escolar,
    estatus,
    tipo_pago
  ) VALUES (
    NEW.id,
    'Seguro + Credencial ' || v_anio_escolar,
    v_config.costo_seguro_credencial,
    NEW.fecha_ingreso,
    v_anio_escolar,
    'pendiente',
    'seguro'
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
        tipo_pago
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/12)',
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad'
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
        tipo_pago
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/12)',
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad'
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
        tipo_pago
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/10)',
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad'
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
        tipo_pago
      ) VALUES (
        NEW.id,
        'Mensualidad ' || TO_CHAR(v_fecha_vencimiento, 'TMMonth YYYY') || ' (' || v_numero_pago || '/10)',
        v_monto_mensualidad,
        v_fecha_vencimiento,
        v_anio_escolar,
        'pendiente',
        'mensualidad'
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
-- 5. POLÍTICAS RLS PARA CONFIGURACIÓN
-- ============================================

ALTER TABLE configuracion_costos ENABLE ROW LEVEL SECURITY;

-- Directora: puede ver y editar
CREATE POLICY "Directora puede ver configuracion_costos"
  ON configuracion_costos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
      AND u.rol = 'directora'
    )
  );

CREATE POLICY "Directora puede insertar configuracion_costos"
  ON configuracion_costos FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
      AND u.rol = 'directora'
    )
  );

CREATE POLICY "Directora puede actualizar configuracion_costos"
  ON configuracion_costos FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
      AND u.rol = 'directora'
    )
  );

-- ============================================
-- 6. FUNCIÓN PARA OBTENER CONFIGURACIÓN ACTUAL
-- ============================================

CREATE OR REPLACE FUNCTION obtener_configuracion_actual()
RETURNS TABLE (
  id UUID,
  costo_inscripcion DECIMAL(10,2),
  costo_seguro_credencial DECIMAL(10,2),
  costo_mensualidad_12 DECIMAL(10,2),
  costo_mensualidad_10 DECIMAL(10,2),
  vigente BOOLEAN,
  vigencia_desde DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.costo_inscripcion,
    c.costo_seguro_credencial,
    c.costo_mensualidad_12,
    c.costo_mensualidad_10,
    c.vigente,
    c.vigencia_desde
  FROM configuracion_costos c
  WHERE c.vigente = true
  ORDER BY c.vigencia_desde DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ✅ LISTO - AHORA EJECUTAR EN SUPABASE
-- ============================================
