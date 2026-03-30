-- ============================================
-- INSERTAR GRADOS INICIALES
-- ============================================
-- Ejecuta este SQL en Supabase SQL Editor

-- Insertar grados típicos de maternal/preescolar
INSERT INTO grados (id, nombre, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'Maternal 1', 1, 2, 15, true, NOW(), NOW()),
  (gen_random_uuid(), 'Maternal 2', 2, 3, 15, true, NOW(), NOW()),
  (gen_random_uuid(), 'Maternal 3', 3, 4, 20, true, NOW(), NOW()),
  (gen_random_uuid(), 'Kinder 1', 4, 5, 20, true, NOW(), NOW()),
  (gen_random_uuid(), 'Kinder 2', 5, 6, 20, true, NOW(), NOW()),
  (gen_random_uuid(), 'Kinder 3', 6, 7, 20, true, NOW(), NOW())
ON CONFLICT (nombre) DO NOTHING;

-- Verificar que se insertaron
SELECT * FROM grados ORDER BY edad_minima;
