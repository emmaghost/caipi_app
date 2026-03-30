-- =====================================================
-- FIX: CORREGIR GRADOS (SOLO MATERNAL Y KINDER 1,2,3)
-- =====================================================

-- 1. ELIMINAR todos los grados incorrectos
DELETE FROM grados WHERE nombre NOT IN ('Maternal', 'Kinder 1', 'Kinder 2', 'Kinder 3');

-- 2. ASEGURARNOS de que existen los grados correctos
INSERT INTO grados (id, nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
VALUES 
    ('maternal-id', 'Maternal', 'Nivel Maternal', 0, 3, 20, true, now(), now()),
    ('kinder-1-id', 'Kinder 1', 'Primer año de Kinder', 3, 4, 25, true, now(), now()),
    ('kinder-2-id', 'Kinder 2', 'Segundo año de Kinder', 4, 5, 25, true, now(), now()),
    ('kinder-3-id', 'Kinder 3', 'Tercer año de Kinder', 5, 6, 25, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    edad_minima = EXCLUDED.edad_minima,
    edad_maxima = EXCLUDED.edad_maxima,
    cupo_maximo = EXCLUDED.cupo_maximo,
    activo = EXCLUDED.activo,
    updated_at = now();

-- 3. VERIFICAR grados correctos
SELECT 
    nombre,
    descripcion,
    edad_minima,
    edad_maxima,
    cupo_maximo,
    activo
FROM grados
WHERE activo = true
ORDER BY 
    CASE 
        WHEN nombre = 'Maternal' THEN 1
        WHEN nombre = 'Kinder 1' THEN 2
        WHEN nombre = 'Kinder 2' THEN 3
        WHEN nombre = 'Kinder 3' THEN 4
    END;
