-- ============================================
-- AGREGAR COLUMNAS FALTANTES A TABLA ALUMNOS
-- ============================================
-- Este script agrega las columnas necesarias para
-- el sistema de planes de pago y becas
-- ============================================

-- 1. Agregar columna fecha_ingreso (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'alumnos' AND column_name = 'fecha_ingreso'
  ) THEN
    ALTER TABLE alumnos ADD COLUMN fecha_ingreso DATE NOT NULL DEFAULT CURRENT_DATE;
    COMMENT ON COLUMN alumnos.fecha_ingreso IS 'Fecha de ingreso del alumno a la escuela';
  END IF;
END $$;

-- 2. Agregar columna plan_pagos (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'alumnos' AND column_name = 'plan_pagos'
  ) THEN
    ALTER TABLE alumnos ADD COLUMN plan_pagos INTEGER DEFAULT 12 CHECK (plan_pagos IN (10, 12));
    COMMENT ON COLUMN alumnos.plan_pagos IS 'Plan de pagos: 10 o 12 mensualidades';
  END IF;
END $$;

-- 3. Agregar columna beca_porcentaje (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'alumnos' AND column_name = 'beca_porcentaje'
  ) THEN
    ALTER TABLE alumnos ADD COLUMN beca_porcentaje INTEGER DEFAULT 0 
      CHECK (beca_porcentaje >= 0 AND beca_porcentaje <= 100);
    COMMENT ON COLUMN alumnos.beca_porcentaje IS 'Porcentaje de beca (0-100). Ej: 20 = 20% de descuento';
  END IF;
END $$;

-- 4. Actualizar registros existentes con valores por defecto
UPDATE alumnos 
SET fecha_ingreso = COALESCE(fecha_ingreso, created_at::date)
WHERE fecha_ingreso IS NULL;

UPDATE alumnos 
SET plan_pagos = COALESCE(plan_pagos, 12)
WHERE plan_pagos IS NULL;

UPDATE alumnos 
SET beca_porcentaje = COALESCE(beca_porcentaje, 0)
WHERE beca_porcentaje IS NULL;

-- ============================================
-- ✅ LISTO
-- ============================================

/*
Este script agrega a la tabla alumnos:
1. ✅ fecha_ingreso (DATE) - Fecha de ingreso del alumno
2. ✅ plan_pagos (INTEGER) - 10 o 12 mensualidades
3. ✅ beca_porcentaje (INTEGER) - Porcentaje de descuento (0-100)

Es seguro ejecutar múltiples veces.
*/
