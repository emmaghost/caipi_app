-- =============================================================================
-- INDICADORES PORTAGE + guía Drive por grado
-- Ejecutar en Supabase SQL Editor (una sola vez).
-- =============================================================================

-- 1) Visibilidad al padre (por niño) + URL de guía Drive (por grado)
ALTER TABLE alumnos
  ADD COLUMN IF NOT EXISTS portage_visible_padre BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE grados
  ADD COLUMN IF NOT EXISTS guia_drive_url TEXT;

COMMENT ON COLUMN alumnos.portage_visible_padre IS
  'Si true, el padre ve la última evaluación Portage (solo lectura).';
COMMENT ON COLUMN grados.guia_drive_url IS
  'URL de Drive con guía de desarrollo del grado (abre en app / descarga).';

-- 2) Lista de indicadores (plantilla) asignada a un grado
CREATE TABLE IF NOT EXISTS portage_listas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grado_id UUID NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL DEFAULT 'Indicadores Portage',
  activa BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_portage_listas_grado ON portage_listas(grado_id);

-- 3) Indicadores de la lista (repeater: solo el nombre/texto)
CREATE TABLE IF NOT EXISTS portage_indicadores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lista_id UUID NOT NULL REFERENCES portage_listas(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  orden INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_portage_indicadores_lista ON portage_indicadores(lista_id, orden);

-- 4) Evaluación (la crea la directora). La gráfica agrupa desde fecha_inicio
--    (1 / 2 / 6 meses), no desde la última edición de la maestra.
CREATE TABLE IF NOT EXISTS portage_evaluaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lista_id UUID NOT NULL REFERENCES portage_listas(id) ON DELETE CASCADE,
  grado_id UUID NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
  titulo TEXT,
  fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_portage_evaluaciones_grado
  ON portage_evaluaciones(grado_id, fecha_inicio DESC);
CREATE INDEX IF NOT EXISTS idx_portage_evaluaciones_lista
  ON portage_evaluaciones(lista_id);

-- 5) Resultados por niño × indicador × evaluación
--    estado: NULL = sin calificar | 'logrado' | 'en_proceso'
CREATE TABLE IF NOT EXISTS portage_resultados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluacion_id UUID NOT NULL REFERENCES portage_evaluaciones(id) ON DELETE CASCADE,
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  indicador_id UUID NOT NULL REFERENCES portage_indicadores(id) ON DELETE CASCADE,
  estado TEXT CHECK (estado IS NULL OR estado IN ('logrado', 'en_proceso')),
  observaciones TEXT,
  actualizado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (evaluacion_id, alumno_id, indicador_id)
);

CREATE INDEX IF NOT EXISTS idx_portage_resultados_alumno
  ON portage_resultados(alumno_id, evaluacion_id);
CREATE INDEX IF NOT EXISTS idx_portage_resultados_eval
  ON portage_resultados(evaluacion_id);

-- 6) RLS básica (directora / staff leen y escriben; padre solo lectura si flag)
ALTER TABLE portage_listas ENABLE ROW LEVEL SECURITY;
ALTER TABLE portage_indicadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE portage_evaluaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE portage_resultados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "portage_listas_staff" ON portage_listas;
CREATE POLICY "portage_listas_staff" ON portage_listas
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

DROP POLICY IF EXISTS "portage_indicadores_staff" ON portage_indicadores;
CREATE POLICY "portage_indicadores_staff" ON portage_indicadores
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

DROP POLICY IF EXISTS "portage_evaluaciones_staff" ON portage_evaluaciones;
CREATE POLICY "portage_evaluaciones_staff" ON portage_evaluaciones
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

DROP POLICY IF EXISTS "portage_resultados_staff" ON portage_resultados;
CREATE POLICY "portage_resultados_staff" ON portage_resultados
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

-- Padre: solo SELECT de resultados de sus hijos si portage_visible_padre
DROP POLICY IF EXISTS "portage_resultados_padre_lectura" ON portage_resultados;
CREATE POLICY "portage_resultados_padre_lectura" ON portage_resultados
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = portage_resultados.alumno_id
        AND a.padre_id = auth.uid()
        AND a.portage_visible_padre = true
    )
  );

DROP POLICY IF EXISTS "portage_evaluaciones_padre_lectura" ON portage_evaluaciones;
CREATE POLICY "portage_evaluaciones_padre_lectura" ON portage_evaluaciones
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM alumnos a
      WHERE a.grado_id = portage_evaluaciones.grado_id
        AND a.padre_id = auth.uid()
        AND a.portage_visible_padre = true
    )
  );

DROP POLICY IF EXISTS "portage_indicadores_padre_lectura" ON portage_indicadores;
CREATE POLICY "portage_indicadores_padre_lectura" ON portage_indicadores
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM portage_listas pl
      JOIN alumnos a ON a.grado_id = pl.grado_id
      WHERE pl.id = portage_indicadores.lista_id
        AND a.padre_id = auth.uid()
        AND a.portage_visible_padre = true
    )
  );

DROP POLICY IF EXISTS "portage_listas_padre_lectura" ON portage_listas;
CREATE POLICY "portage_listas_padre_lectura" ON portage_listas
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.grado_id = portage_listas.grado_id
        AND a.padre_id = auth.uid()
        AND a.portage_visible_padre = true
    )
  );

-- Relación recomendada (varias profesoras → mismo grado):
-- tabla profesores.grado_id ya permite N filas con el mismo grado_id.
