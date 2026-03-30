-- ============================================
-- ACTUALIZACIÓN COMPLETA - SISTEMA DE PAGOS
-- ============================================

-- 1. Agregar columna recibido_por si no existe
ALTER TABLE pagos 
ADD COLUMN IF NOT EXISTS recibido_por TEXT CHECK (recibido_por IN ('directora', 'joss'));

-- 2. Agregar comentarios a las columnas
COMMENT ON COLUMN pagos.metodo_pago IS 'Método de pago: Efectivo, Transferencia, Tarjeta';
COMMENT ON COLUMN pagos.recibido_por IS 'Quién recibió el pago: directora o joss';
COMMENT ON COLUMN pagos.referencia IS 'Número de recibo o referencia del pago';

-- ============================================
-- CONCEPTOS DE PAGO AUTOMÁTICOS
-- ============================================

-- Al crear un alumno, se generan automáticamente:

-- 1. INSCRIPCIÓN ANUAL: $2,000.00
--    - Se genera una vez
--    - Límite: día 15 del mes de inscripción

-- 2. SEGURO + CREDENCIAL: $500.00
--    - Se genera una vez
--    - Límite: día 15 del mes de inscripción

-- 3. COLEGIATURAS MENSUALES: $1,500.00 c/u (x12 meses)
--    - Se generan 12 pagos (Enero - Diciembre)
--    - Límite: día 10 de cada mes

-- ============================================
-- PAGOS OPCIONALES (Se agregan manualmente)
-- ============================================

-- 4. LIBROS: Variable por grado
--    - Maternal: $600
--    - Kinder 1: $700
--    - Kinder 2: $800
--    - Kinder 3: $900

-- 5. UNIFORMES: $250 por pieza
--    - A pedido del padre
--    - Se registra cantidad

-- ============================================
-- EJEMPLO DE ACTUALIZACIÓN MANUAL
-- ============================================

-- Acreditar un pago:
-- UPDATE pagos 
-- SET 
--   pagado = true,
--   fecha_pago = CURRENT_DATE,
--   metodo_pago = 'Efectivo',
--   recibido_por = 'directora',
--   referencia = 'REC-001'
-- WHERE id = 'id-del-pago';

-- ============================================
-- VERIFICAR QUE TODO ESTÁ OK
-- ============================================

-- Ver estructura de la tabla pagos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'pagos'
ORDER BY ordinal_position;

-- Ver todos los pagos pendientes
SELECT 
  p.mes,
  p.concepto,
  p.monto,
  p.fecha_limite,
  a.nombre || ' ' || a.apellidos as alumno
FROM pagos p
JOIN alumnos a ON p.alumno_id = a.id
WHERE p.pagado = false
ORDER BY p.fecha_limite ASC;
