-- ============================================
-- MÓDULO DE EVENTOS E INCIDENTES - CAIPI
-- ============================================

-- ============================================
-- 1. TABLA DE EVENTOS
-- ============================================
CREATE TABLE IF NOT EXISTS eventos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  fecha_evento DATE NOT NULL,
  hora_inicio TIME,
  hora_fin TIME,
  lugar TEXT,
  tipo TEXT NOT NULL CHECK (tipo IN ('academico', 'festivo', 'reunion', 'clausura', 'otro')),
  para_todos BOOLEAN DEFAULT true,
  grados_ids UUID[], -- Array de IDs de grados (si no es para todos)
  foto_url TEXT,
  creado_por UUID REFERENCES usuarios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON eventos(fecha_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_activo ON eventos(activo);

-- ============================================
-- 2. TABLA DE TIPOS DE INCIDENTES (CATÁLOGO)
-- ============================================
CREATE TABLE IF NOT EXISTS tipos_incidentes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL UNIQUE, -- 'Golpe leve', 'Pelea', 'Excelente comportamiento', etc.
  descripcion TEXT,
  categoria TEXT NOT NULL CHECK (categoria IN ('accidente', 'comportamiento', 'logro', 'otro')),
  nivel INTEGER NOT NULL CHECK (nivel >= 1 AND nivel <= 5),
  -- Nivel 1: Info general
  -- Nivel 2: Atención menor
  -- Nivel 3: Requiere seguimiento
  -- Nivel 4: NOTIFICAR A PADRE
  -- Nivel 5: URGENTE - NOTIFICAR A PADRE
  color TEXT DEFAULT '#808080',
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tipos_incidentes_nivel ON tipos_incidentes(nivel);
CREATE INDEX IF NOT EXISTS idx_tipos_incidentes_activo ON tipos_incidentes(activo);

-- ============================================
-- 3. MODIFICAR TABLA INCIDENTES (DROP Y RECREAR)
-- ============================================
DROP TABLE IF EXISTS incidentes CASCADE;

CREATE TABLE incidentes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  tipo_incidente_id UUID REFERENCES tipos_incidentes(id),
  nivel INTEGER NOT NULL CHECK (nivel >= 1 AND nivel <= 5),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  fecha TIMESTAMPTZ DEFAULT NOW(),
  reportado_por UUID REFERENCES usuarios(id),
  atendido BOOLEAN DEFAULT false,
  padre_notificado BOOLEAN DEFAULT false,
  fecha_notificacion TIMESTAMPTZ,
  foto_url TEXT,
  observaciones TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_incidentes_alumno ON incidentes(alumno_id);
CREATE INDEX idx_incidentes_fecha ON incidentes(fecha);
CREATE INDEX idx_incidentes_nivel ON incidentes(nivel);
CREATE INDEX idx_incidentes_tipo ON incidentes(tipo_incidente_id);

-- ============================================
-- 4. INSERTAR TIPOS DE INCIDENTES INICIALES
-- ============================================

-- Nivel 1: Información general (no crítico)
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Olvido material', 'No trajo material solicitado', 'otro', 1, '#90EE90'),
('Tarea incompleta', 'No completó tarea', 'comportamiento', 1, '#87CEEB');

-- Nivel 2: Atención menor
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Golpe leve', 'Golpe o caída sin lesión grave', 'accidente', 2, '#FFD700'),
('Falta de atención', 'Distracción en clase', 'comportamiento', 2, '#FFA500');

-- Nivel 3: Requiere seguimiento
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Conflicto con compañero', 'Discusión o empujón con otro niño', 'comportamiento', 3, '#FF8C00'),
('Malestar leve', 'Dolor de estómago o cabeza', 'accidente', 3, '#FF6347');

-- Nivel 4: NOTIFICAR A PADRE
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Golpe con moretón', 'Golpe que dejó marca', 'accidente', 4, '#FF4500'),
('Conducta agresiva', 'Golpeó o mordió a otro niño', 'comportamiento', 4, '#DC143C'),
('Fiebre', 'Temperatura alta', 'accidente', 4, '#B22222');

-- Nivel 5: URGENTE - NOTIFICAR INMEDIATAMENTE
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Accidente grave', 'Requiere atención médica inmediata', 'accidente', 5, '#8B0000'),
('Agresión severa', 'Conducta violenta que pone en riesgo a otros', 'comportamiento', 5, '#800000');

-- LOGROS (Positivos - Nivel 1)
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Excelente participación', 'Destacó en clase', 'logro', 1, '#32CD32'),
('Ayudó a compañero', 'Mostró solidaridad', 'logro', 1, '#00FA9A'),
('Logro académico', 'Avance significativo en aprendizaje', 'logro', 1, '#00FF00');

-- ============================================
-- 5. RLS (ROW LEVEL SECURITY)
-- ============================================

-- Eventos
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver eventos activos"
  ON eventos FOR SELECT
  USING (activo = true);

CREATE POLICY "Directora y profesores pueden crear eventos"
  ON eventos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor')
    )
  );

CREATE POLICY "Directora y profesores pueden actualizar eventos"
  ON eventos FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor')
    )
  );

-- Tipos de Incidentes
ALTER TABLE tipos_incidentes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver tipos activos"
  ON tipos_incidentes FOR SELECT
  USING (activo = true);

CREATE POLICY "Solo directora puede crear tipos"
  ON tipos_incidentes FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol = 'directora'
    )
  );

CREATE POLICY "Solo directora puede actualizar tipos"
  ON tipos_incidentes FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol = 'directora'
    )
  );

-- Incidentes
ALTER TABLE incidentes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Padres pueden ver incidentes de sus hijos"
  ON incidentes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM alumnos
      WHERE alumnos.id = incidentes.alumno_id
      AND alumnos.padre_id = auth.uid()
    )
  );

CREATE POLICY "Directora y profesores pueden ver todos los incidentes"
  ON incidentes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor')
    )
  );

CREATE POLICY "Directora y profesores pueden crear incidentes"
  ON incidentes FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor')
    )
  );

CREATE POLICY "Directora y profesores pueden actualizar incidentes"
  ON incidentes FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor')
    )
  );

-- ============================================
-- 6. TRIGGERS PARA NOTIFICACIONES AUTOMÁTICAS
-- ============================================

-- Función para notificar al padre cuando nivel >= 4
CREATE OR REPLACE FUNCTION notificar_incidente_grave()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.nivel >= 4 AND NEW.padre_notificado = false THEN
    -- Aquí podrías insertar en tabla de notificaciones
    -- Por ahora solo actualizamos el campo
    NEW.padre_notificado := true;
    NEW.fecha_notificacion := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notificar_incidente
  BEFORE INSERT ON incidentes
  FOR EACH ROW
  EXECUTE FUNCTION notificar_incidente_grave();

-- ============================================
-- VERIFICAR QUE TODO SE CREÓ CORRECTAMENTE
-- ============================================

SELECT 'Eventos' as tabla, COUNT(*) as registros FROM eventos
UNION ALL
SELECT 'Tipos de Incidentes', COUNT(*) FROM tipos_incidentes
UNION ALL
SELECT 'Incidentes', COUNT(*) FROM incidentes;
