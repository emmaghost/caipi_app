-- ============================================
-- MÓDULO DE EVENTOS E INCIDENTES - CAIPI (CORREGIDO)
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
-- 3. TABLA INCIDENTES (CREAR SI NO EXISTE)
-- ============================================
CREATE TABLE IF NOT EXISTS incidentes (
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

CREATE INDEX IF NOT EXISTS idx_incidentes_alumno ON incidentes(alumno_id);
CREATE INDEX IF NOT EXISTS idx_incidentes_fecha ON incidentes(fecha);
CREATE INDEX IF NOT EXISTS idx_incidentes_nivel ON incidentes(nivel);
CREATE INDEX IF NOT EXISTS idx_incidentes_tipo ON incidentes(tipo_incidente_id);

-- ============================================
-- 4. INSERTAR TIPOS DE INCIDENTES INICIALES
-- (CON ON CONFLICT PARA EVITAR DUPLICADOS)
-- ============================================

-- Nivel 1: Información general (no crítico)
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Olvido material', 'No trajo material solicitado', 'otro', 1, '#90EE90'),
('Tarea incompleta', 'No completó tarea', 'comportamiento', 1, '#87CEEB')
ON CONFLICT (nombre) DO NOTHING;

-- Nivel 2: Atención menor
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Golpe leve', 'Golpe o caída sin lesión grave', 'accidente', 2, '#FFD700'),
('Falta de atención', 'Distracción en clase', 'comportamiento', 2, '#FFA500')
ON CONFLICT (nombre) DO NOTHING;

-- Nivel 3: Requiere seguimiento
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Conflicto con compañero', 'Discusión o empujón con otro niño', 'comportamiento', 3, '#FF8C00'),
('Malestar leve', 'Dolor de estómago o cabeza', 'accidente', 3, '#FF6347')
ON CONFLICT (nombre) DO NOTHING;

-- Nivel 4: NOTIFICAR A PADRE
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Golpe con moretón', 'Golpe que dejó marca', 'accidente', 4, '#FF4500'),
('Pelea', 'Altercado físico con otro niño', 'comportamiento', 4, '#DC143C'),
('Fiebre', 'Temperatura elevada', 'accidente', 4, '#B22222')
ON CONFLICT (nombre) DO NOTHING;

-- Nivel 5: URGENTE - NOTIFICAR A PADRE
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Lesión grave', 'Requiere atención médica inmediata', 'accidente', 5, '#8B0000'),
('Conducta agresiva grave', 'Comportamiento violento', 'comportamiento', 5, '#800000'),
('Crisis de salud', 'Emergencia médica', 'accidente', 5, '#8B0000')
ON CONFLICT (nombre) DO NOTHING;

-- Logros (positivos) - Nivel 1
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
('Excelente comportamiento', 'Destacó por su conducta ejemplar', 'logro', 1, '#00FF00'),
('Aprendizaje destacado', 'Logró aprendizaje significativo', 'logro', 1, '#32CD32'),
('Ayudó a compañero', 'Mostró solidaridad y empatía', 'logro', 1, '#00FA9A')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================
-- 5. RLS PARA EVENTOS
-- ============================================
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;

-- Todos pueden ver eventos activos
DROP POLICY IF EXISTS "Ver eventos activos" ON eventos;
CREATE POLICY "Ver eventos activos"
  ON eventos FOR SELECT
  USING (activo = true);

-- Directora y profesores admin pueden gestionar eventos
DROP POLICY IF EXISTS "Gestionar eventos" ON eventos;
CREATE POLICY "Gestionar eventos"
  ON eventos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ============================================
-- 6. RLS PARA TIPOS DE INCIDENTES
-- ============================================
ALTER TABLE tipos_incidentes ENABLE ROW LEVEL SECURITY;

-- Todos pueden ver tipos de incidentes activos
DROP POLICY IF EXISTS "Ver tipos de incidentes" ON tipos_incidentes;
CREATE POLICY "Ver tipos de incidentes"
  ON tipos_incidentes FOR SELECT
  USING (activo = true);

-- Solo directora puede modificar el catálogo
DROP POLICY IF EXISTS "Gestionar tipos de incidentes" ON tipos_incidentes;
CREATE POLICY "Gestionar tipos de incidentes"
  ON tipos_incidentes FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol = 'directora'
    )
  );

-- ============================================
-- 7. RLS PARA INCIDENTES
-- ============================================
ALTER TABLE incidentes ENABLE ROW LEVEL SECURITY;

-- Directora y profesores pueden ver todos los incidentes
DROP POLICY IF EXISTS "Ver incidentes directora/profesores" ON incidentes;
CREATE POLICY "Ver incidentes directora/profesores"
  ON incidentes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

-- Padres solo ven incidentes de sus hijos
DROP POLICY IF EXISTS "Padres ven incidentes de sus hijos" ON incidentes;
CREATE POLICY "Padres ven incidentes de sus hijos"
  ON incidentes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = incidentes.alumno_id
      AND a.padre_id = auth.uid()
    )
  );

-- Directora y profesores pueden crear/modificar incidentes
DROP POLICY IF EXISTS "Crear/modificar incidentes" ON incidentes;
CREATE POLICY "Crear/modificar incidentes"
  ON incidentes FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

-- ============================================
-- 8. TRIGGER PARA NOTIFICAR AUTOMÁTICAMENTE
-- ============================================
CREATE OR REPLACE FUNCTION notificar_padre_incidente()
RETURNS TRIGGER AS $$
BEGIN
  -- Si el nivel es 4 o 5, marcar como que requiere notificación
  IF NEW.nivel >= 4 THEN
    NEW.padre_notificado = false; -- Se marcará true cuando se envíe la notificación
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notificar_incidente ON incidentes;
CREATE TRIGGER trigger_notificar_incidente
  BEFORE INSERT OR UPDATE ON incidentes
  FOR EACH ROW
  EXECUTE FUNCTION notificar_padre_incidente();

-- ============================================
-- ✅ LISTO! MÓDULO DE EVENTOS E INCIDENTES
-- ============================================
