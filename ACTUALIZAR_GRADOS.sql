-- ============================================
-- ACTUALIZAR TABLA GRADOS - CAIPI
-- ============================================
-- Este script actualiza la tabla grados para que coincida
-- con el modelo Dart y permite insertar grados correctamente

-- 1. Eliminar columnas antiguas que no se usan
ALTER TABLE grados DROP COLUMN IF EXISTS nivel;
ALTER TABLE grados DROP COLUMN IF EXISTS ciclo_escolar;
ALTER TABLE grados DROP COLUMN IF EXISTS total_alumnos;
ALTER TABLE grados DROP COLUMN IF EXISTS color_grupo;

-- 2. Agregar columnas nuevas si no existen
ALTER TABLE grados ADD COLUMN IF NOT EXISTS edad_minima INTEGER;
ALTER TABLE grados ADD COLUMN IF NOT EXISTS edad_maxima INTEGER;
ALTER TABLE grados ADD COLUMN IF NOT EXISTS cupo_maximo INTEGER DEFAULT 20;
ALTER TABLE grados ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE grados ADD COLUMN IF NOT EXISTS descripcion TEXT;

-- 3. Renombrar capacidad_maxima a cupo_maximo si existe
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='grados' AND column_name='capacidad_maxima'
    ) THEN
        ALTER TABLE grados RENAME COLUMN capacidad_maxima TO cupo_maximo;
    END IF;
END $$;

-- 4. Crear trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_grados_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_grados_updated_at ON grados;
CREATE TRIGGER trigger_update_grados_updated_at
  BEFORE UPDATE ON grados
  FOR EACH ROW
  EXECUTE FUNCTION update_grados_updated_at();

-- 5. Verificar estructura final
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'grados'
ORDER BY ordinal_position;

-- ✅ Ahora la tabla grados tiene:
-- id, nombre, edad_minima, edad_maxima, cupo_maximo, activo, created_at, updated_at, descripcion
