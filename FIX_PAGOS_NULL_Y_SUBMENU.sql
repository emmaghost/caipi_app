-- ============================================
-- 🔧 FIX: FECHA_VENCIMIENTO NULLABLE + TIPO_PAGO
-- ============================================
-- Este script corrige:
-- 1. Hace fecha_vencimiento NULLABLE (para evitar errores)
-- 2. Asegura que tipo_pago exista
-- 3. Actualiza pagos existentes con tipo_pago correcto
-- ============================================

-- 1. Hacer fecha_vencimiento NULLABLE
DO $$ 
BEGIN
  -- Eliminar constraint NOT NULL si existe
  ALTER TABLE pagos ALTER COLUMN fecha_vencimiento DROP NOT NULL;
  
  -- Asegurar que la columna exista
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'fecha_vencimiento'
  ) THEN
    ALTER TABLE pagos ADD COLUMN fecha_vencimiento DATE;
  END IF;
  
  RAISE NOTICE '✅ fecha_vencimiento ahora es NULLABLE';
END $$;

-- 2. Asegurar que tipo_pago exista
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'tipo_pago'
  ) THEN
    ALTER TABLE pagos ADD COLUMN tipo_pago TEXT;
  END IF;
  
  RAISE NOTICE '✅ tipo_pago existe';
END $$;

-- 3. Actualizar tipo_pago basado en concepto
UPDATE pagos 
SET tipo_pago = CASE
  WHEN concepto ILIKE '%inscripci%n%' THEN 'inscripcion'
  WHEN concepto ILIKE '%mensualidad%' OR concepto ILIKE '%colegiatura%' THEN 'mensualidad'
  WHEN concepto ILIKE '%libro%' THEN 'extracurricular'
  WHEN concepto ILIKE '%uniforme%' THEN 'extracurricular'
  WHEN concepto ILIKE '%clase%extra%' THEN 'extracurricular'
  WHEN concepto ILIKE '%seguro%' THEN 'seguro'
  ELSE 'otro'
END
WHERE tipo_pago IS NULL;

-- 4. Asegurar valores por defecto
UPDATE pagos 
SET tipo_pago = 'mensualidad'
WHERE tipo_pago IS NULL OR tipo_pago = '';

-- ============================================
-- ✅ LISTO
-- ============================================

/*
DESPUÉS DE EJECUTAR ESTE SCRIPT:
1. ✅ fecha_vencimiento ya NO causará errores de null
2. ✅ tipo_pago está clasificado correctamente
3. ✅ Puedes filtrar por tipo en la app

TIPOS DE PAGO:
- inscripcion: Inscripción anual
- mensualidad: Colegiaturas mensuales
- seguro: Seguro escolar
- extracurricular: Libros, uniformes, clases extra
- otro: Pagos misceláneos
*/
