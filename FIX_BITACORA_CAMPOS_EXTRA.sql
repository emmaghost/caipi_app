-- Campos adicionales en bitácora diaria (ejecutar en Supabase SQL Editor)

ALTER TABLE bitacora_diaria
  ADD COLUMN IF NOT EXISTS tomo_agua boolean NOT NULL DEFAULT false;

ALTER TABLE bitacora_diaria
  ADD COLUMN IF NOT EXISTS respeto_demas boolean NOT NULL DEFAULT false;

ALTER TABLE bitacora_diaria
  ADD COLUMN IF NOT EXISTS realizo_actividades boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN bitacora_diaria.tomo_agua IS '¿Tomó agua durante el día?';
COMMENT ON COLUMN bitacora_diaria.respeto_demas IS '¿Respetó a los demás?';
COMMENT ON COLUMN bitacora_diaria.realizo_actividades IS '¿Realizó sus actividades?';
