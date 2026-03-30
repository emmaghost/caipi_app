-- ============================================
-- VERIFICAR Y CORREGIR GRADOS CON UUID
-- ============================================

-- 1. Ver los grados actuales
SELECT id, nombre, LENGTH(id) as longitud_id 
FROM grados;

-- 2. Si los IDs no son UUIDs válidos, eliminar y recrear
DELETE FROM grados;

-- 3. Insertar con UUIDs válidos
INSERT INTO grados (id, nombre, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'Maternal 1', 1, 2, 15, true, NOW(), NOW()),
  (gen_random_uuid(), 'Maternal 2', 2, 3, 15, true, NOW(), NOW()),
  (gen_random_uuid(), 'Maternal 3', 3, 4, 20, true, NOW(), NOW()),
  (gen_random_uuid(), 'Kinder 1', 4, 5, 20, true, NOW(), NOW()),
  (gen_random_uuid(), 'Kinder 2', 5, 6, 20, true, NOW(), NOW()),
  (gen_random_uuid(), 'Kinder 3', 6, 7, 20, true, NOW(), NOW());

-- 4. Verificar que se insertaron correctamente
SELECT 
  id,
  nombre,
  edad_minima,
  edad_maxima,
  cupo_maximo,
  LENGTH(id::text) as longitud_uuid
FROM grados
ORDER BY edad_minima;

-- Un UUID válido debe tener 36 caracteres (con guiones)
-- Ejemplo: 123e4567-e89b-12d3-a456-426614174000
