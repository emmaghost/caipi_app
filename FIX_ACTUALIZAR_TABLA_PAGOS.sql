-- ============================================
-- ACTUALIZAR ESTRUCTURA DE TABLA PAGOS
-- ============================================
-- Este script actualiza la tabla pagos existente
-- para agregar los campos necesarios para pagos parciales y becas
-- ============================================

-- 1. Agregar columna estatus (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'estatus'
  ) THEN
    ALTER TABLE pagos ADD COLUMN estatus TEXT DEFAULT 'pendiente' 
      CHECK (estatus IN ('pendiente', 'parcial', 'pagado', 'vencido', 'cancelado'));
    COMMENT ON COLUMN pagos.estatus IS 'Estado del pago: pendiente, parcial, pagado, vencido, cancelado';
  END IF;
END $$;

-- 2. Agregar columna monto_pagado (si no existe)
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

-- 3. Cambiar nombre de fecha_limite a fecha_vencimiento (si existe la columna antigua)
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
  END IF;
  
  -- Si no existe fecha_vencimiento, agregarla
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'fecha_vencimiento'
  ) THEN
    ALTER TABLE pagos ADD COLUMN fecha_vencimiento DATE NOT NULL DEFAULT CURRENT_DATE;
  END IF;
END $$;

-- 4. Agregar columna forma_pago (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'forma_pago'
  ) THEN
    ALTER TABLE pagos ADD COLUMN forma_pago TEXT;
    COMMENT ON COLUMN pagos.forma_pago IS 'Forma de pago: Efectivo, Transferencia, Tarjeta, etc.';
  END IF;
END $$;

-- 5. Agregar columna referencia (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'referencia'
  ) THEN
    ALTER TABLE pagos ADD COLUMN referencia TEXT;
    COMMENT ON COLUMN pagos.referencia IS 'Número de referencia o folio';
  END IF;
END $$;

-- 6. Agregar columna notas (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'notas'
  ) THEN
    ALTER TABLE pagos ADD COLUMN notas TEXT;
    COMMENT ON COLUMN pagos.notas IS 'Notas adicionales del pago';
  END IF;
END $$;

-- 7. Agregar columna anio_escolar (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'anio_escolar'
  ) THEN
    ALTER TABLE pagos ADD COLUMN anio_escolar INTEGER;
    COMMENT ON COLUMN pagos.anio_escolar IS 'Año escolar del pago (2024, 2025, etc.)';
  END IF;
END $$;

-- 8. Agregar columna tipo_pago (si no existe)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'tipo_pago'
  ) THEN
    ALTER TABLE pagos ADD COLUMN tipo_pago TEXT;
    COMMENT ON COLUMN pagos.tipo_pago IS 'Tipo de pago: inscripcion, mensualidad, seguro, otro';
  END IF;
END $$;

-- 9. Migrar datos existentes: actualizar estatus basado en columna pagado (si existe)
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pagos' AND column_name = 'pagado'
  ) THEN
    -- Actualizar estatus basado en la columna pagado (boolean)
    UPDATE pagos SET estatus = 'pagado' WHERE pagado = true;
    UPDATE pagos SET estatus = 'pendiente' WHERE pagado = false OR pagado IS NULL;
  END IF;
END $$;

-- 10. Eliminar constraint antiguo de pagos (si existe)
DO $$ 
BEGIN
  ALTER TABLE pagos DROP CONSTRAINT IF EXISTS pagos_estatus_check;
END $$;

-- 11. Agregar constraint nuevo
ALTER TABLE pagos DROP CONSTRAINT IF EXISTS pagos_estatus_check;
ALTER TABLE pagos ADD CONSTRAINT pagos_estatus_check 
  CHECK (estatus IN ('pendiente', 'parcial', 'pagado', 'vencido', 'cancelado'));

-- ============================================
-- ✅ LISTO
-- ============================================

/*
Este script:
1. ✅ Agrega columna estatus (pendiente, parcial, pagado, vencido, cancelado)
2. ✅ Agrega columna monto_pagado (para abonos)
3. ✅ Renombra fecha_limite a fecha_vencimiento
4. ✅ Agrega columna forma_pago
5. ✅ Agrega columna referencia
6. ✅ Agrega columna notas
7. ✅ Agrega columna anio_escolar
8. ✅ Agrega columna tipo_pago
9. ✅ Migra datos existentes (pagado → estatus)
10. ✅ Es seguro ejecutar múltiples veces (verifica antes de agregar)

DESPUÉS de ejecutar este script:
- Ejecuta FIX_PAGOS_PARCIALES.sql
- Ejecuta FIX_SISTEMA_BECAS.sql
*/
