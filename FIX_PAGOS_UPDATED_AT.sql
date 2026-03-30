-- Columna que faltaba (la app ya no la exige; ordena por created_at).
-- Ejecuta esto si quieres updated_at para otros usos o reportes.

ALTER TABLE pagos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

UPDATE pagos SET updated_at = COALESCE(updated_at, created_at, NOW());
