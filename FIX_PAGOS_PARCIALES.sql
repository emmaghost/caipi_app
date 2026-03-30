-- ============================================
-- CAIPI - SISTEMA DE PAGOS PARCIALES
-- ============================================
-- Este script agrega:
-- 1. Tabla de abonos (pagos parciales)
-- 2. Campo monto_pagado en pagos
-- 3. Función para calcular saldo pendiente
-- 4. Trigger para actualizar estatus automáticamente
-- ============================================

-- ============================================
-- 1. AGREGAR CAMPO monto_pagado A PAGOS
-- ============================================

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'monto_pagado'
  ) THEN
    ALTER TABLE pagos ADD COLUMN monto_pagado DECIMAL(10,2) DEFAULT 0.00;
    COMMENT ON COLUMN pagos.monto_pagado IS 'Monto total pagado (suma de abonos)';
  END IF;
END $$;

-- ============================================
-- 2. CREAR TABLA DE ABONOS
-- ============================================

CREATE TABLE IF NOT EXISTS abonos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pago_id UUID NOT NULL REFERENCES pagos(id) ON DELETE CASCADE,
  monto DECIMAL(10,2) NOT NULL CHECK (monto > 0),
  fecha_abono DATE NOT NULL DEFAULT CURRENT_DATE,
  forma_pago TEXT,
  referencia TEXT,
  notas TEXT,
  recibo_folio TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES usuarios(id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_abonos_pago ON abonos(pago_id);
CREATE INDEX IF NOT EXISTS idx_abonos_fecha ON abonos(fecha_abono);
CREATE INDEX IF NOT EXISTS idx_abonos_folio ON abonos(recibo_folio);

-- ============================================
-- 3. FUNCIÓN: Calcular Saldo Pendiente
-- ============================================

CREATE OR REPLACE FUNCTION calcular_saldo_pago(p_pago_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  v_monto_total DECIMAL(10,2);
  v_monto_pagado DECIMAL(10,2);
BEGIN
  -- Obtener monto total del pago
  SELECT monto INTO v_monto_total
  FROM pagos
  WHERE id = p_pago_id;
  
  -- Calcular suma de abonos
  SELECT COALESCE(SUM(monto), 0) INTO v_monto_pagado
  FROM abonos
  WHERE pago_id = p_pago_id;
  
  -- Retornar saldo pendiente
  RETURN v_monto_total - v_monto_pagado;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. FUNCIÓN: Actualizar Monto Pagado
-- ============================================

CREATE OR REPLACE FUNCTION actualizar_monto_pagado()
RETURNS TRIGGER AS $$
DECLARE
  v_total_abonos DECIMAL(10,2);
  v_monto_pago DECIMAL(10,2);
  v_nuevo_estatus TEXT;
BEGIN
  -- Calcular total de abonos
  SELECT COALESCE(SUM(monto), 0) INTO v_total_abonos
  FROM abonos
  WHERE pago_id = NEW.pago_id;
  
  -- Obtener monto del pago
  SELECT monto INTO v_monto_pago
  FROM pagos
  WHERE id = NEW.pago_id;
  
  -- Determinar nuevo estatus
  IF v_total_abonos >= v_monto_pago THEN
    v_nuevo_estatus := 'pagado';
  ELSIF v_total_abonos > 0 THEN
    v_nuevo_estatus := 'parcial';
  ELSE
    v_nuevo_estatus := 'pendiente';
  END IF;
  
  -- Actualizar pago
  UPDATE pagos
  SET 
    monto_pagado = v_total_abonos,
    estatus = v_nuevo_estatus,
    fecha_pago = CASE 
      WHEN v_nuevo_estatus = 'pagado' THEN NEW.fecha_abono
      ELSE fecha_pago
    END,
    updated_at = NOW()
  WHERE id = NEW.pago_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. TRIGGER: Al insertar abono
-- ============================================

DROP TRIGGER IF EXISTS trigger_actualizar_monto_pagado ON abonos;

CREATE TRIGGER trigger_actualizar_monto_pagado
  AFTER INSERT ON abonos
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_monto_pagado();

-- ============================================
-- 6. FUNCIÓN: Generar Folio de Recibo
-- ============================================

CREATE OR REPLACE FUNCTION generar_folio_recibo()
RETURNS TEXT AS $$
DECLARE
  v_anio TEXT;
  v_consecutivo INTEGER;
  v_folio TEXT;
BEGIN
  -- Año actual
  v_anio := TO_CHAR(CURRENT_DATE, 'YYYY');
  
  -- Obtener consecutivo del año
  SELECT COALESCE(MAX(CAST(SUBSTRING(recibo_folio FROM '\d+$') AS INTEGER)), 0) + 1
  INTO v_consecutivo
  FROM abonos
  WHERE recibo_folio LIKE 'REC-' || v_anio || '-%';
  
  -- Generar folio: REC-2026-0001
  v_folio := 'REC-' || v_anio || '-' || LPAD(v_consecutivo::TEXT, 4, '0');
  
  RETURN v_folio;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. TRIGGER: Generar folio automático
-- ============================================

CREATE OR REPLACE FUNCTION asignar_folio_recibo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.recibo_folio IS NULL THEN
    NEW.recibo_folio := generar_folio_recibo();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_asignar_folio_recibo ON abonos;

CREATE TRIGGER trigger_asignar_folio_recibo
  BEFORE INSERT ON abonos
  FOR EACH ROW
  EXECUTE FUNCTION asignar_folio_recibo();

-- ============================================
-- 8. ACTUALIZAR ESTATUS EN TABLA PAGOS
-- ============================================

-- Agregar nuevo estatus 'parcial'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'pagos_estatus_check'
  ) THEN
    ALTER TABLE pagos DROP CONSTRAINT IF EXISTS pagos_estatus_check;
  END IF;
END $$;

ALTER TABLE pagos DROP CONSTRAINT IF EXISTS pagos_estatus_check;
ALTER TABLE pagos ADD CONSTRAINT pagos_estatus_check 
  CHECK (estatus IN ('pendiente', 'parcial', 'pagado', 'vencido', 'cancelado'));

-- ============================================
-- 9. VISTA: Resumen de Pagos con Abonos
-- ============================================

CREATE OR REPLACE VIEW vista_pagos_abonos AS
SELECT 
  p.id AS pago_id,
  p.alumno_id,
  a.nombre || ' ' || a.apellidos AS alumno_nombre,
  p.concepto,
  p.monto AS monto_total,
  p.monto_pagado,
  p.monto - p.monto_pagado AS saldo_pendiente,
  p.estatus,
  p.fecha_vencimiento,
  p.fecha_pago,
  COUNT(ab.id) AS numero_abonos,
  ARRAY_AGG(
    JSON_BUILD_OBJECT(
      'id', ab.id,
      'monto', ab.monto,
      'fecha', ab.fecha_abono,
      'folio', ab.recibo_folio
    ) ORDER BY ab.fecha_abono
  ) FILTER (WHERE ab.id IS NOT NULL) AS abonos
FROM pagos p
LEFT JOIN alumnos a ON p.alumno_id = a.id
LEFT JOIN abonos ab ON p.id = ab.pago_id
GROUP BY 
  p.id, 
  p.alumno_id, 
  a.nombre, 
  a.apellidos, 
  p.concepto, 
  p.monto, 
  p.monto_pagado, 
  p.estatus, 
  p.fecha_vencimiento, 
  p.fecha_pago;

-- ============================================
-- 10. POLÍTICAS RLS PARA ABONOS
-- ============================================

ALTER TABLE abonos ENABLE ROW LEVEL SECURITY;

-- Directora puede ver todos los abonos
CREATE POLICY "Directora puede ver abonos"
  ON abonos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
      AND u.rol = 'directora'
    )
  );

-- Directora puede insertar abonos
CREATE POLICY "Directora puede insertar abonos"
  ON abonos FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
      AND u.rol = 'directora'
    )
  );

-- Padres pueden ver sus abonos
CREATE POLICY "Padres pueden ver sus abonos"
  ON abonos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM pagos p
      INNER JOIN alumnos a ON p.alumno_id = a.id
      INNER JOIN usuarios u ON a.padre_id = u.id
      WHERE p.id = abonos.pago_id
      AND u.id = auth.uid()
    )
  );

-- ============================================
-- ✅ LISTO - EJECUTAR EN SUPABASE
-- ============================================

/*
FUNCIONALIDADES AGREGADAS:

1. ✅ Campo monto_pagado en tabla pagos
2. ✅ Tabla abonos con historial de pagos parciales
3. ✅ Estatus 'parcial' para pagos a medias
4. ✅ Folio único automático (REC-2026-0001)
5. ✅ Trigger que actualiza monto_pagado automáticamente
6. ✅ Trigger que cambia estatus según abonos
7. ✅ Vista para consultar pagos con sus abonos
8. ✅ Función para calcular saldo pendiente
9. ✅ Políticas RLS para seguridad

EJEMPLOS DE USO:

-- Insertar un abono
INSERT INTO abonos (pago_id, monto, forma_pago, referencia)
VALUES ('uuid-del-pago', 500.00, 'Efectivo', 'Abono 1/3');

-- Ver saldo pendiente
SELECT calcular_saldo_pago('uuid-del-pago');

-- Ver pagos con abonos
SELECT * FROM vista_pagos_abonos WHERE alumno_id = 'uuid-alumno';
*/
