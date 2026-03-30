-- =====================================================
-- FIX: PAGOS EXISTENTES SIN FECHA_VENCIMIENTO
-- =====================================================
-- Este script corrige los pagos que fueron creados con el trigger antiguo

-- 1. AGREGAR fecha_vencimiento a pagos que no la tienen
--    Usamos la fecha de creación + 30 días como fecha de vencimiento por defecto
UPDATE pagos
SET fecha_vencimiento = (created_at + interval '30 days')::date
WHERE fecha_vencimiento IS NULL;

-- 2. ELIMINAR PAGOS DUPLICADOS (si los hay)
--    Solo mantener el pago más reciente por alumno/concepto
DELETE FROM pagos p1
WHERE EXISTS (
    SELECT 1 FROM pagos p2
    WHERE p2.alumno_id = p1.alumno_id 
    AND p2.concepto = p1.concepto
    AND p2.created_at > p1.created_at
);

-- 3. VERIFICAR resultados
SELECT 
    COUNT(*) as total_pagos,
    COUNT(CASE WHEN fecha_vencimiento IS NULL THEN 1 END) as sin_fecha_vencimiento,
    COUNT(CASE WHEN estatus = 'pendiente' THEN 1 END) as pendientes,
    COUNT(CASE WHEN estatus = 'pagado' THEN 1 END) as pagados
FROM pagos;

-- 4. VERIFICAR pagos por alumno
SELECT 
    a.nombre || ' ' || a.apellidos as alumno,
    COUNT(p.id) as total_pagos,
    COUNT(CASE WHEN p.estatus = 'pendiente' THEN 1 END) as pendientes,
    COUNT(CASE WHEN p.estatus = 'pagado' THEN 1 END) as pagados
FROM alumnos a
LEFT JOIN pagos p ON p.alumno_id = a.id
GROUP BY a.id, a.nombre, a.apellidos
ORDER BY a.nombre;
