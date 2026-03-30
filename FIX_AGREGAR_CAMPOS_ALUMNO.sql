-- =====================================================
-- FIX: AGREGAR CAMPOS FALTANTES A TABLA ALUMNOS
-- =====================================================
-- Dirección completa, CURP, y cartilla de vacunas

-- 1. AGREGAR columnas de dirección
ALTER TABLE alumnos
ADD COLUMN IF NOT EXISTS calle VARCHAR(200),
ADD COLUMN IF NOT EXISTS colonia VARCHAR(100),
ADD COLUMN IF NOT EXISTS codigo_postal VARCHAR(10),
ADD COLUMN IF NOT EXISTS ciudad VARCHAR(100) DEFAULT 'Iztapalapa',
ADD COLUMN IF NOT EXISTS estado VARCHAR(100) DEFAULT 'CDMX';

-- 2. AGREGAR columna CURP
ALTER TABLE alumnos
ADD COLUMN IF NOT EXISTS curp VARCHAR(18) UNIQUE;

-- 3. AGREGAR columnas de cartilla de vacunas
ALTER TABLE alumnos
ADD COLUMN IF NOT EXISTS cartilla_completa BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS vacunas_faltantes TEXT;

-- 4. CREAR índice para búsqueda por CURP
CREATE INDEX IF NOT EXISTS idx_alumnos_curp ON alumnos(curp);

-- 5. COMENTARIOS para documentación
COMMENT ON COLUMN alumnos.calle IS 'Calle y número de la dirección del alumno';
COMMENT ON COLUMN alumnos.colonia IS 'Colonia o barrio';
COMMENT ON COLUMN alumnos.codigo_postal IS 'Código postal (CP)';
COMMENT ON COLUMN alumnos.curp IS 'CURP único del alumno';
COMMENT ON COLUMN alumnos.cartilla_completa IS 'Si la cartilla de vacunación está completa';
COMMENT ON COLUMN alumnos.vacunas_faltantes IS 'Lista de vacunas faltantes (solo si cartilla_completa = false)';

-- 6. VERIFICAR estructura actualizada
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'alumnos'
AND column_name IN ('calle', 'colonia', 'codigo_postal', 'curp', 'cartilla_completa', 'vacunas_faltantes')
ORDER BY column_name;
