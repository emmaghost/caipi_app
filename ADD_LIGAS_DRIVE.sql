-- =============================================================================
-- Ligas / guías de Drive — alcance GENERAL o por GRUPO(s)
-- Ejecutar en Supabase SQL Editor (instalación limpia).
-- Si ya corriste la versión anterior, usa FIX_LIGAS_DRIVE_POR_GRADO.sql
-- =============================================================================

CREATE TABLE IF NOT EXISTS ligas_drive (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  url TEXT NOT NULL,
  -- general = todos | grados = uno o varios grupos
  alcance TEXT NOT NULL DEFAULT 'general'
    CHECK (alcance IN ('general', 'grados')),
  activa BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ligas_drive_alcance
  ON ligas_drive(alcance, activa);

CREATE TABLE IF NOT EXISTS ligas_drive_grados (
  liga_id UUID NOT NULL REFERENCES ligas_drive(id) ON DELETE CASCADE,
  grado_id UUID NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
  PRIMARY KEY (liga_id, grado_id)
);

CREATE INDEX IF NOT EXISTS idx_ligas_drive_grados_grado
  ON ligas_drive_grados(grado_id);

ALTER TABLE ligas_drive ENABLE ROW LEVEL SECURITY;
ALTER TABLE ligas_drive_grados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ligas_drive_staff" ON ligas_drive;
CREATE POLICY "ligas_drive_staff" ON ligas_drive
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

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

DROP POLICY IF EXISTS "ligas_drive_grados_padre_lectura" ON ligas_drive_grados;
CREATE POLICY "ligas_drive_grados_padre_lectura" ON ligas_drive_grados
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.grado_id = ligas_drive_grados.grado_id
        AND a.padre_id = auth.uid()
    )
  );
