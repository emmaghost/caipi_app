-- OBLIGATORIO para que "Directora / Joss / Otro" quede guardado al acreditar.
-- Sin esta columna, el pago puede acreditarse pero NO se guarda quién recibió.
-- Supabase → SQL Editor → ejecutar.

ALTER TABLE pagos ADD COLUMN IF NOT EXISTS recibido_por_nombre TEXT;

COMMENT ON COLUMN pagos.recibido_por_nombre IS
  'Quien recibió el dinero en caja (Directora, Joss, u otro nombre).';
