-- =============================================================================
-- BITÁCORA DIARIA – actualización completa (Supabase → SQL Editor)
-- Ejecuta TODO el script de una vez. Si algún paso ya lo aplicaste, puede
-- mostrar aviso "already exists" / "column already nullable": en ese caso ignóralo.
-- =============================================================================

-- 1) profesor_id: la FK apunta a profesores.id, no al usuario de auth.
--    La directora no está en profesores → debe poder guardar con profesor_id NULL.
ALTER TABLE bitacora_diaria
  ALTER COLUMN profesor_id DROP NOT NULL;

COMMENT ON COLUMN bitacora_diaria.profesor_id IS
  'ID en tabla profesores. NULL si la registró la directora.';

-- 2) Campos nuevos de actividades (sí/no con switch en la app)
ALTER TABLE bitacora_diaria
  ADD COLUMN IF NOT EXISTS tomo_agua boolean NOT NULL DEFAULT false;

ALTER TABLE bitacora_diaria
  ADD COLUMN IF NOT EXISTS respeto_demas boolean NOT NULL DEFAULT false;

ALTER TABLE bitacora_diaria
  ADD COLUMN IF NOT EXISTS realizo_actividades boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN bitacora_diaria.tomo_agua IS '¿Tomó agua?';
COMMENT ON COLUMN bitacora_diaria.respeto_demas IS '¿Respetó a los demás?';
COMMENT ON COLUMN bitacora_diaria.realizo_actividades IS '¿Realizó sus actividades?';

-- (Los demás ya suelen existir: comio, pipi, popo, lavo_dientes, siesta, estado_animo, observaciones, etc.)

-- 3) Comió: permitir 'mas_o_menos' además de si/no/medio (evita error 23514)
ALTER TABLE bitacora_diaria
  DROP CONSTRAINT IF EXISTS bitacora_diaria_comio_check;
ALTER TABLE bitacora_diaria
  ADD CONSTRAINT bitacora_diaria_comio_check
  CHECK (comio IS NULL OR comio IN ('si', 'no', 'medio', 'mas_o_menos'));
