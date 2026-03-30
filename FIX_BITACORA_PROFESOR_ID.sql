-- La bitácora guardaba auth.uid en profesor_id, pero la FK apunta a profesores.id.
-- La directora no tiene fila en profesores: permitir NULL en profesor_id.
ALTER TABLE bitacora_diaria
  ALTER COLUMN profesor_id DROP NOT NULL;

COMMENT ON COLUMN bitacora_diaria.profesor_id IS
  'ID en tabla profesores. NULL si la registró la directora.';
