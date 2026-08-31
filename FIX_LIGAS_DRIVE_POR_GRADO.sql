-- =============================================================================
-- Ligas Drive: alcance por GRUPO(s) o GENERAL (no por alumno)
-- Ejecutar en Supabase si ya corriste ADD_LIGAS_DRIVE.sql
-- =============================================================================

-- 1) Tabla de grupos asignados a una liga
CREATE TABLE IF NOT EXISTS ligas_drive_grados (
  liga_id UUID NOT NULL REFERENCES ligas_drive(id) ON DELETE CASCADE,
  grado_id UUID NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
  PRIMARY KEY (liga_id, grado_id)
);

CREATE INDEX IF NOT EXISTS idx_ligas_drive_grados_grado
  ON ligas_drive_grados(grado_id);

-- 2) Permitir alcance 'grados' (y migrar 'alumnos' → 'grados' si existía)
ALTER TABLE ligas_drive DROP CONSTRAINT IF EXISTS ligas_drive_alcance_check;
ALTER TABLE ligas_drive
  ADD CONSTRAINT ligas_drive_alcance_check
  CHECK (alcance IN ('general', 'grados', 'alumnos'));

UPDATE ligas_drive SET alcance = 'grados' WHERE alcance = 'alumnos';

ALTER TABLE ligas_drive DROP CONSTRAINT IF EXISTS ligas_drive_alcance_check;
ALTER TABLE ligas_drive
  ADD CONSTRAINT ligas_drive_alcance_check
  CHECK (alcance IN ('general', 'grados'));

-- 3) RLS grados
ALTER TABLE ligas_drive_grados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ligas_drive_grados_staff" ON ligas_drive_grados;
CREATE POLICY "ligas_drive_grados_staff" ON ligas_drive_grados
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

DROP POLICY IF EXISTS "ligas_drive_grados_padre_lectura" ON ligas_drive_grados;
CREATE POLICY "ligas_drive_grados_padre_lectura" ON ligas_drive_grados
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.grado_id = ligas_drive_grados.grado_id
        AND a.padre_id = auth.uid()
    )
  );

-- 4) Actualizar lectura padre: general O grado del hijo
DROP POLICY IF EXISTS "ligas_drive_padre_lectura" ON ligas_drive;
CREATE POLICY "ligas_drive_padre_lectura" ON ligas_drive
  FOR SELECT USING (
    activa = true
    AND (
      alcance = 'general'
      OR EXISTS (
        SELECT 1
        FROM ligas_drive_grados ldg
        JOIN alumnos a ON a.grado_id = ldg.grado_id
        WHERE ldg.liga_id = ligas_drive.id
          AND a.padre_id = auth.uid()
      )
    )
  );

-- Opcional: ya no usamos alumnos por liga
DROP TABLE IF EXISTS ligas_drive_alumnos CASCADE;
