-- =============================================================================
-- Comió: la app puede guardar 'mas_o_menos'. El CHECK antiguo solo permitía
-- 'si', 'no', 'medio' → error 23514 bitacora_diaria_comio_check
-- Ejecuta en Supabase → SQL Editor (una vez).
-- =============================================================================

ALTER TABLE bitacora_diaria
  DROP CONSTRAINT IF EXISTS bitacora_diaria_comio_check;

ALTER TABLE bitacora_diaria
  ADD CONSTRAINT bitacora_diaria_comio_check
  CHECK (
    comio IS NULL
    OR comio IN ('si', 'no', 'medio', 'mas_o_menos')
  );

COMMENT ON COLUMN bitacora_diaria.comio IS
  '¿Comió? si | no | medio (legacy) | mas_o_menos';
