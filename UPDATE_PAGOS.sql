-- ============================================
-- ACTUALIZACIÓN TABLA PAGOS
-- Agregar campo para registrar quién recibió el pago
-- ============================================

-- Agregar columna recibido_por
ALTER TABLE pagos 
ADD COLUMN IF NOT EXISTS recibido_por TEXT CHECK (recibido_por IN ('directora', 'joss'));

-- Actualizar comentario de la columna
COMMENT ON COLUMN pagos.recibido_por IS 'A quién se le entregó el pago: directora o joss';

-- Ejemplo de uso:
-- UPDATE pagos 
-- SET 
--   pagado = true,
--   fecha_pago = CURRENT_DATE,
--   metodo_pago = 'Efectivo',
--   recibido_por = 'joss'
-- WHERE id = 'id-del-pago';
