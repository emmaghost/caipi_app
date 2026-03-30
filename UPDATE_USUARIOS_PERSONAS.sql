-- ============================================
-- ACTUALIZACIÓN - USUARIOS Y PERSONAS AUTORIZADAS
-- ============================================

-- 1. Verificar que la tabla usuarios tenga todos los campos
-- (Si ya ejecutaste DATABASE_COMPLETA.sql, esto ya está hecho)

-- Agregar columnas si no existen en usuarios
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS apellidos TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS whatsapp TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS foto_url TEXT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Actualizar tabla personas_autorizadas si ya existe
-- Agregar columnas faltantes
ALTER TABLE personas_autorizadas ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 3. Verificar estructura de personas_autorizadas
-- Si la tabla no existe, crearla:
CREATE TABLE IF NOT EXISTS personas_autorizadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  parentesco TEXT NOT NULL,
  telefono TEXT NOT NULL,
  identificacion TEXT,
  foto_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índice si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'personas_autorizadas' 
    AND indexname = 'idx_personas_autorizadas_alumno'
  ) THEN
    CREATE INDEX idx_personas_autorizadas_alumno ON personas_autorizadas(alumno_id);
  END IF;
END $$;

-- 4. Habilitar RLS en personas_autorizadas
ALTER TABLE personas_autorizadas ENABLE ROW LEVEL SECURITY;

-- 5. Políticas RLS para personas_autorizadas
DROP POLICY IF EXISTS "Directora puede gestionar personas autorizadas" ON personas_autorizadas;
DROP POLICY IF EXISTS "Padres pueden ver personas autorizadas de sus hijos" ON personas_autorizadas;

CREATE POLICY "Directora puede gestionar personas autorizadas"
  ON personas_autorizadas
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios 
      WHERE id = auth.uid() 
      AND rol = 'directora'
    )
  );

CREATE POLICY "Padres pueden ver personas autorizadas de sus hijos"
  ON personas_autorizadas
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM alumnos 
      WHERE alumnos.id = personas_autorizadas.alumno_id
      AND alumnos.padre_id = auth.uid()
    )
  );

-- 6. Verificar que todo está correcto
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'usuarios'
ORDER BY ordinal_position;

SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'personas_autorizadas'
ORDER BY ordinal_position;

-- ============================================
-- LISTO! Ahora puedes usar el sistema
-- ============================================
