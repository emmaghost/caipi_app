-- ============================================
-- 🔧 FIX COMPLETO: TABLA PAGOS
-- ============================================
-- Este script corrige TODA la estructura de pagos:
-- 1. Migra columnas antiguas a nuevas
-- 2. Agrega campos faltantes
-- 3. Hace fecha_vencimiento NULLABLE
-- 4. Agrega tipo_pago con valores correctos
-- ============================================

-- PASO 1: Renombrar columnas antiguas
-- ============================================

-- Renombrar fecha_limite → fecha_vencimiento
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'fecha_limite'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'fecha_vencimiento'
  ) THEN
    ALTER TABLE pagos RENAME COLUMN fecha_limite TO fecha_vencimiento;
    RAISE NOTICE '✅ Renombrado: fecha_limite → fecha_vencimiento';
  END IF;
END $$;

-- PASO 2: Hacer fecha_vencimiento NULLABLE
-- ============================================
DO $$ 
BEGIN
  ALTER TABLE pagos ALTER COLUMN fecha_vencimiento DROP NOT NULL;
  RAISE NOTICE '✅ fecha_vencimiento ahora es NULLABLE';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '⚠️ fecha_vencimiento ya era nullable o no existe';
END $$;

-- PASO 3: Agregar columna estatus
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'estatus'
  ) THEN
    ALTER TABLE pagos ADD COLUMN estatus TEXT DEFAULT 'pendiente' 
      CHECK (estatus IN ('pendiente', 'parcial', 'pagado', 'vencido', 'cancelado'));
    RAISE NOTICE '✅ Columna estatus agregada';
  END IF;
END $$;

-- PASO 4: Migrar pagado → estatus
-- ============================================
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'pagado'
  ) THEN
    -- Actualizar estatus basado en pagado
    UPDATE pagos 
    SET estatus = CASE 
      WHEN pagado = true THEN 'pagado'
      WHEN pagado = false AND fecha_vencimiento IS NOT NULL AND fecha_vencimiento < CURRENT_DATE THEN 'vencido'
      ELSE 'pendiente'
    END
    WHERE estatus IS NULL OR estatus = 'pendiente';
    
    RAISE NOTICE '✅ Migrado: pagado → estatus';
  END IF;
END $$;

-- PASO 5: Agregar monto_pagado
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'monto_pagado'
  ) THEN
    ALTER TABLE pagos ADD COLUMN monto_pagado DECIMAL(10,2) DEFAULT 0.00;
    
    -- Si pagado=true, copiar el monto completo
    UPDATE pagos 
    SET monto_pagado = monto 
    WHERE pagado = true;
    
    RAISE NOTICE '✅ Columna monto_pagado agregada';
  END IF;
END $$;

-- PASO 6: Agregar tipo_pago
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'tipo_pago'
  ) THEN
    ALTER TABLE pagos ADD COLUMN tipo_pago TEXT;
    RAISE NOTICE '✅ Columna tipo_pago agregada';
  END IF;
END $$;

-- PASO 7: Clasificar pagos existentes por tipo
-- ============================================
UPDATE pagos 
SET tipo_pago = CASE
  WHEN concepto ILIKE '%inscripci%n%' THEN 'inscripcion'
  WHEN concepto ILIKE '%mensualidad%' OR concepto ILIKE '%colegiatura%' THEN 'mensualidad'
  WHEN concepto ILIKE '%libro%' THEN 'extracurricular'
  WHEN concepto ILIKE '%uniforme%' THEN 'extracurricular'
  WHEN concepto ILIKE '%clase%extra%' OR concepto ILIKE '%extracurricular%' THEN 'extracurricular'
  WHEN concepto ILIKE '%baile%' OR concepto ILIKE '%danza%' THEN 'extracurricular'
  WHEN concepto ILIKE '%deporte%' OR concepto ILIKE '%futbol%' THEN 'extracurricular'
  WHEN concepto ILIKE '%seguro%' THEN 'seguro'
  WHEN mes ILIKE '%enero%' OR mes ILIKE '%febrero%' OR mes ILIKE '%marzo%' 
       OR mes ILIKE '%abril%' OR mes ILIKE '%mayo%' OR mes ILIKE '%junio%'
       OR mes ILIKE '%julio%' OR mes ILIKE '%agosto%' OR mes ILIKE '%septiembre%'
       OR mes ILIKE '%octubre%' OR mes ILIKE '%noviembre%' OR mes ILIKE '%diciembre%' THEN 'mensualidad'
  ELSE 'mensualidad'
END
WHERE tipo_pago IS NULL OR tipo_pago = '';

-- PASO 8: Agregar columnas adicionales si no existen
-- ============================================

-- forma_pago (renombrar metodo_pago si existe)
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'metodo_pago'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'forma_pago'
  ) THEN
    ALTER TABLE pagos RENAME COLUMN metodo_pago TO forma_pago;
    RAISE NOTICE '✅ Renombrado: metodo_pago → forma_pago';
  ELSIF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'forma_pago'
  ) THEN
    ALTER TABLE pagos ADD COLUMN forma_pago TEXT;
    RAISE NOTICE '✅ Columna forma_pago agregada';
  END IF;
END $$;

-- referencia (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'referencia'
  ) THEN
    ALTER TABLE pagos ADD COLUMN referencia TEXT;
    RAISE NOTICE '✅ Columna referencia agregada';
  END IF;
END $$;

-- notas (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'notas'
  ) THEN
    ALTER TABLE pagos ADD COLUMN notas TEXT;
    RAISE NOTICE '✅ Columna notas agregada';
  END IF;
END $$;

-- anio_escolar (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'anio_escolar'
  ) THEN
    ALTER TABLE pagos ADD COLUMN anio_escolar INTEGER;
    
    -- Llenar con año actual para pagos existentes
    UPDATE pagos 
    SET anio_escolar = EXTRACT(YEAR FROM CURRENT_DATE)
    WHERE anio_escolar IS NULL;
    
    RAISE NOTICE '✅ Columna anio_escolar agregada';
  END IF;
END $$;

-- PASO 9: Actualizar updated_at si no existe
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE pagos ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    RAISE NOTICE '✅ Columna updated_at agregada';
  END IF;
END $$;

-- PASO 10: Verificar estructura final
-- ============================================
DO $$
DECLARE
  col_record RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📋 ESTRUCTURA FINAL DE TABLA PAGOS:';
  RAISE NOTICE '=====================================';
  
  FOR col_record IN 
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'pagos'
    ORDER BY ordinal_position
  LOOP
    RAISE NOTICE '  - %: % (%)', 
      col_record.column_name, 
      col_record.data_type,
      CASE WHEN col_record.is_nullable = 'YES' THEN 'NULL OK' ELSE 'NOT NULL' END;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '📊 TIPOS DE PAGO EN LA BASE:';
  RAISE NOTICE '=====================================';
  
  FOR col_record IN 
    SELECT tipo_pago, COUNT(*) as cantidad
    FROM pagos
    GROUP BY tipo_pago
    ORDER BY cantidad DESC
  LOOP
    RAISE NOTICE '  - %: % pagos', col_record.tipo_pago, col_record.cantidad;
  END LOOP;
END $$;

-- ============================================
-- ✅ LISTO - AHORA EJECUTA ESTO EN SUPABASE
-- ============================================

/*
📋 DESPUÉS DE EJECUTAR:

1. ✅ Todas las columnas están correctas
2. ✅ fecha_vencimiento es NULLABLE (no más errores)
3. ✅ tipo_pago clasifica: inscripcion, mensualidad, extracurricular, seguro
4. ✅ estatus reemplaza pagado (boolean → text)
5. ✅ monto_pagado permite pagos parciales

🔍 VERIFICAR EN LA APP:
- Entra a "Gestión de Pagos"
- Deberías ver 2 tabs: "Pagos de Alumnos" y "Extracurriculares"
- NO debe mostrar error de tipo null

⚠️ IMPORTANTE:
Después de ejecutar este SQL, actualiza el código de:
lib/services/supabase_service.dart
para que use los nombres de columnas correctos.
*/
