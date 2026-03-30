-- Ejecutar en Supabase SQL Editor para corregir el error:
-- "column reference 'codigo' is ambiguous" al generar QR temporal

CREATE OR REPLACE FUNCTION generar_codigo_qr()
RETURNS TEXT AS $$
DECLARE
  v_codigo TEXT;
  existe BOOLEAN;
BEGIN
  LOOP
    v_codigo := UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8));
    SELECT EXISTS(SELECT 1 FROM qr_temporales WHERE qr_temporales.codigo = v_codigo) INTO existe;
    EXIT WHEN NOT existe;
  END LOOP;
  RETURN v_codigo;
END;
$$ LANGUAGE plpgsql;
