-- ============================================
-- BASE DE DATOS COMPLETA CAIPI
-- Sistema de Gestión Escolar
-- ============================================

-- Limpiar tablas existentes (cuidado en producción)
DROP TABLE IF EXISTS galeria CASCADE;
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS participantes_clases CASCADE;
DROP TABLE IF EXISTS clases_extracurriculares CASCADE;
DROP TABLE IF EXISTS menu_maternal CASCADE;
DROP TABLE IF EXISTS bitacora_diaria CASCADE;
DROP TABLE IF EXISTS control_salidas CASCADE;
DROP TABLE IF EXISTS personas_autorizadas CASCADE;
DROP TABLE IF EXISTS incidentes CASCADE;
DROP TABLE IF EXISTS calificaciones CASCADE;
DROP TABLE IF EXISTS pagos CASCADE;
DROP TABLE IF EXISTS alumnos CASCADE;
DROP TABLE IF EXISTS profesores CASCADE;
DROP TABLE IF EXISTS grados CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

-- ============================================
-- 1. USUARIOS (Directora, Profesores, Padres)
-- ============================================
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('directora', 'profesor', 'padre')),
  nombre TEXT NOT NULL,
  apellidos TEXT,
  telefono TEXT,
  whatsapp TEXT,
  foto_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);

-- ============================================
-- 2. GRADOS (Maternal, Kinder 1, 2, 3)
-- ============================================
CREATE TABLE grados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL, -- 'Maternal', 'Kinder 1', 'Kinder 2', 'Kinder 3'
  nivel TEXT NOT NULL, -- 'maternal', 'kinder'
  ciclo_escolar TEXT NOT NULL, -- '2025-2026'
  capacidad_maxima INTEGER DEFAULT 20,
  total_alumnos INTEGER DEFAULT 0,
  color_grupo TEXT, -- Para UI (ej: '#FF69B4')
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_grados_ciclo ON grados(ciclo_escolar);

-- ============================================
-- 3. PROFESORES
-- ============================================
CREATE TABLE profesores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  grado_id UUID REFERENCES grados(id) ON DELETE SET NULL,
  especialidad TEXT, -- 'Kinder', 'Danza', 'Inglés'
  fecha_ingreso DATE,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profesores_usuario ON profesores(usuario_id);
CREATE INDEX idx_profesores_grado ON profesores(grado_id);

-- ============================================
-- 4. ALUMNOS
-- ============================================
CREATE TABLE alumnos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  genero TEXT CHECK (genero IN ('niño', 'niña')),
  grado_id UUID REFERENCES grados(id) ON DELETE SET NULL,
  padre_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
  foto_url TEXT,
  foto_default_genero TEXT, -- 'nino' o 'nina' para usar imagen por default
  alergias TEXT,
  condiciones_medicas TEXT,
  contacto_emergencia_nombre TEXT,
  contacto_emergencia_telefono TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alumnos_grado ON alumnos(grado_id);
CREATE INDEX idx_alumnos_padre ON alumnos(padre_id);
CREATE INDEX idx_alumnos_activo ON alumnos(activo);

-- ============================================
-- 5. PERSONAS AUTORIZADAS PARA RECOGER
-- ============================================
CREATE TABLE personas_autorizadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  parentesco TEXT NOT NULL, -- 'Madre', 'Padre', 'Abuelo', 'Tío', etc.
  telefono TEXT NOT NULL,
  identificacion TEXT, -- INE, Pasaporte, etc.
  foto_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_personas_autorizadas_alumno ON personas_autorizadas(alumno_id);

-- ============================================
-- 6. CONTROL DE SALIDAS (Entrada/Salida)
-- ============================================
CREATE TABLE control_salidas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  hora_entrada TIME,
  quien_trajo TEXT, -- Nombre de quien trajo
  hora_salida TIME,
  quien_recogio TEXT, -- Nombre de quien recogió
  persona_autorizada_id UUID REFERENCES personas_autorizadas(id),
  observaciones TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_control_salidas_alumno ON control_salidas(alumno_id);
CREATE INDEX idx_control_salidas_fecha ON control_salidas(fecha);

-- ============================================
-- 7. BITÁCORA DIARIA (Kinder 1, 2, 3)
-- ============================================
CREATE TABLE bitacora_diaria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  profesor_id UUID REFERENCES profesores(id) ON DELETE SET NULL,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  comio TEXT CHECK (comio IN ('si', 'no', 'medio')),
  pipi BOOLEAN DEFAULT false,
  popo BOOLEAN DEFAULT false,
  lavo_dientes BOOLEAN DEFAULT false,
  siesta BOOLEAN DEFAULT false,
  animo TEXT CHECK (animo IN ('feliz', 'normal', 'triste', 'irritable')),
  observaciones TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(alumno_id, fecha)
);

CREATE INDEX idx_bitacora_alumno ON bitacora_diaria(alumno_id);
CREATE INDEX idx_bitacora_fecha ON bitacora_diaria(fecha);

-- ============================================
-- 8. MENÚ MATERNAL (Diario)
-- ============================================
CREATE TABLE menu_maternal (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  desayuno TEXT,
  colacion_manana TEXT,
  comida TEXT,
  colacion_tarde TEXT,
  observaciones TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(fecha)
);

CREATE INDEX idx_menu_fecha ON menu_maternal(fecha);

-- ============================================
-- 9. PAGOS
-- ============================================
CREATE TABLE pagos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  mes TEXT NOT NULL, -- 'Enero 2026'
  concepto TEXT DEFAULT 'Mensualidad',
  monto DECIMAL(10,2) NOT NULL,
  fecha_limite DATE NOT NULL,
  pagado BOOLEAN DEFAULT false,
  fecha_pago DATE,
  metodo_pago TEXT, -- 'Efectivo', 'Transferencia', 'Tarjeta'
  recibido_por TEXT CHECK (recibido_por IN ('directora', 'joss')), -- Quién recibió el pago
  referencia TEXT, -- Número de recibo/referencia
  comprobante_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pagos_alumno ON pagos(alumno_id);
CREATE INDEX idx_pagos_pagado ON pagos(pagado);
CREATE INDEX idx_pagos_fecha_limite ON pagos(fecha_limite);

-- ============================================
-- 10. CALIFICACIONES (Evaluaciones)
-- ============================================
CREATE TABLE calificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  materia TEXT NOT NULL, -- 'Matemáticas', 'Español', 'Inglés', etc.
  periodo TEXT NOT NULL, -- 'Bimestre 1', 'Bimestre 2', etc.
  calificacion DECIMAL(4,2), -- 0-10
  nivel TEXT CHECK (nivel IN ('excelente', 'bueno', 'regular', 'necesita_apoyo')),
  comentarios TEXT,
  fecha DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_calificaciones_alumno ON calificaciones(alumno_id);

-- ============================================
-- 11. INCIDENTES/REPORTES
-- ============================================
CREATE TABLE incidentes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('accidente', 'comportamiento', 'logro', 'otro')),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  gravedad TEXT CHECK (gravedad IN ('baja', 'media', 'alta')),
  atendido BOOLEAN DEFAULT false,
  padre_notificado BOOLEAN DEFAULT false,
  fecha TIMESTAMPTZ DEFAULT NOW(),
  reportado_por UUID REFERENCES usuarios(id),
  foto_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_incidentes_alumno ON incidentes(alumno_id);
CREATE INDEX idx_incidentes_fecha ON incidentes(fecha);

-- ============================================
-- 12. NOTIFICACIONES
-- ============================================
CREATE TABLE notificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  tipo TEXT CHECK (tipo IN ('aviso', 'urgente', 'recordatorio', 'tarea')),
  enviado_por UUID REFERENCES usuarios(id),
  para_rol TEXT CHECK (para_rol IN ('todos', 'padres', 'profesores')),
  para_grado_id UUID REFERENCES grados(id), -- NULL = todos
  leido_por UUID[] DEFAULT '{}', -- Array de IDs de usuarios que la leyeron
  fecha_publicacion TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notificaciones_fecha ON notificaciones(fecha_publicacion);
CREATE INDEX idx_notificaciones_grado ON notificaciones(para_grado_id);

-- ============================================
-- 13. GALERÍA DE FOTOS
-- ============================================
CREATE TABLE galeria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT,
  descripcion TEXT,
  foto_url TEXT NOT NULL,
  grado_id UUID REFERENCES grados(id),
  fecha_evento DATE DEFAULT CURRENT_DATE,
  subido_por UUID REFERENCES usuarios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_galeria_grado ON galeria(grado_id);
CREATE INDEX idx_galeria_fecha ON galeria(fecha_evento);

-- ============================================
-- 14. CLASES EXTRACURRICULARES
-- ============================================
CREATE TABLE clases_extracurriculares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL, -- 'Danza', 'Inglés', 'Música', etc.
  descripcion TEXT,
  profesor_id UUID REFERENCES profesores(id),
  dias_semana TEXT[], -- ['Lunes', 'Miércoles', 'Viernes']
  hora_inicio TIME,
  hora_fin TIME,
  costo_mensual DECIMAL(10,2),
  cupo_maximo INTEGER DEFAULT 15,
  permite_externos BOOLEAN DEFAULT false, -- Si permite mamás u otras personas externas
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clases_extra_activo ON clases_extracurriculares(activo);

-- ============================================
-- 15. PARTICIPANTES EN CLASES EXTRACURRICULARES
-- ============================================
CREATE TABLE participantes_clases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clase_id UUID NOT NULL REFERENCES clases_extracurriculares(id) ON DELETE CASCADE,
  alumno_id UUID REFERENCES alumnos(id) ON DELETE CASCADE, -- NULL si es externo
  tipo_participante TEXT CHECK (tipo_participante IN ('alumno', 'externo')),
  -- Datos si es externo (mamá, etc.)
  nombre_externo TEXT,
  apellidos_externo TEXT,
  telefono_externo TEXT,
  email_externo TEXT,
  fecha_inscripcion DATE DEFAULT CURRENT_DATE,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_participantes_clase ON participantes_clases(clase_id);
CREATE INDEX idx_participantes_alumno ON participantes_clases(alumno_id);

-- ============================================
-- FUNCIONES Y TRIGGERS
-- ============================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alumnos_updated_at BEFORE UPDATE ON alumnos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pagos_updated_at BEFORE UPDATE ON pagos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bitacora_updated_at BEFORE UPDATE ON bitacora_diaria FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para actualizar total de alumnos en grado
CREATE OR REPLACE FUNCTION actualizar_total_alumnos()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.activo = true THEN
    UPDATE grados SET total_alumnos = total_alumnos + 1 WHERE id = NEW.grado_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.grado_id IS DISTINCT FROM NEW.grado_id THEN
      UPDATE grados SET total_alumnos = total_alumnos - 1 WHERE id = OLD.grado_id AND total_alumnos > 0;
      UPDATE grados SET total_alumnos = total_alumnos + 1 WHERE id = NEW.grado_id;
    END IF;
    IF OLD.activo = true AND NEW.activo = false THEN
      UPDATE grados SET total_alumnos = total_alumnos - 1 WHERE id = NEW.grado_id AND total_alumnos > 0;
    ELSIF OLD.activo = false AND NEW.activo = true THEN
      UPDATE grados SET total_alumnos = total_alumnos + 1 WHERE id = NEW.grado_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.activo = true THEN
    UPDATE grados SET total_alumnos = total_alumnos - 1 WHERE id = OLD.grado_id AND total_alumnos > 0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_total_alumnos
AFTER INSERT OR UPDATE OR DELETE ON alumnos
FOR EACH ROW EXECUTE FUNCTION actualizar_total_alumnos();

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar grados
INSERT INTO grados (nombre, nivel, ciclo_escolar, color_grupo) VALUES
  ('Maternal', 'maternal', '2025-2026', '#FFB6C1'),
  ('Kinder 1', 'kinder', '2025-2026', '#87CEEB'),
  ('Kinder 2', 'kinder', '2025-2026', '#FFD700'),
  ('Kinder 3', 'kinder', '2025-2026', '#90EE90');

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE profesores ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumnos ENABLE ROW LEVEL SECURITY;
ALTER TABLE personas_autorizadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_salidas ENABLE ROW LEVEL SECURITY;
ALTER TABLE bitacora_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_maternal ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE calificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE galeria ENABLE ROW LEVEL SECURITY;
ALTER TABLE clases_extracurriculares ENABLE ROW LEVEL SECURITY;
ALTER TABLE participantes_clases ENABLE ROW LEVEL SECURITY;
ALTER TABLE grados ENABLE ROW LEVEL SECURITY;

-- Políticas para GRADOS (todos pueden leer)
CREATE POLICY "Grados son públicos" ON grados FOR SELECT USING (true);
CREATE POLICY "Solo directora puede modificar grados" ON grados FOR ALL USING (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- Políticas para USUARIOS
CREATE POLICY "Usuarios pueden ver su propio perfil" ON usuarios FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Directora puede ver todos los usuarios" ON usuarios FOR SELECT USING (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- Políticas para ALUMNOS
CREATE POLICY "Padres ven solo sus hijos" ON alumnos FOR SELECT USING (
  padre_id = auth.uid()
);
CREATE POLICY "Profesores ven alumnos de su grupo" ON alumnos FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profesores p
    WHERE p.usuario_id = auth.uid() AND p.grado_id = alumnos.grado_id
  )
);
CREATE POLICY "Directora ve todos los alumnos" ON alumnos FOR ALL USING (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- Políticas para BITÁCORA
CREATE POLICY "Padres ven bitácora de sus hijos" ON bitacora_diaria FOR SELECT USING (
  EXISTS (SELECT 1 FROM alumnos WHERE id = bitacora_diaria.alumno_id AND padre_id = auth.uid())
);
CREATE POLICY "Profesores ven/editan bitácora de su grupo" ON bitacora_diaria FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profesores p JOIN alumnos a ON p.grado_id = a.grado_id
    WHERE p.usuario_id = auth.uid() AND a.id = bitacora_diaria.alumno_id
  )
);
CREATE POLICY "Directora ve toda la bitácora" ON bitacora_diaria FOR ALL USING (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- Políticas para PAGOS
CREATE POLICY "Padres ven pagos de sus hijos" ON pagos FOR SELECT USING (
  EXISTS (SELECT 1 FROM alumnos WHERE id = pagos.alumno_id AND padre_id = auth.uid())
);
CREATE POLICY "Directora gestiona todos los pagos" ON pagos FOR ALL USING (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- Políticas para NOTIFICACIONES (todos pueden leer)
CREATE POLICY "Notificaciones son visibles para todos" ON notificaciones FOR SELECT USING (true);
CREATE POLICY "Profesores y directora pueden crear notificaciones" ON notificaciones FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('profesor', 'directora'))
);

-- Políticas para GALERÍA (todos pueden ver)
CREATE POLICY "Galería visible para todos" ON galeria FOR SELECT USING (true);
CREATE POLICY "Profesores y directora pueden subir fotos" ON galeria FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('profesor', 'directora'))
);

-- Políticas similares para las demás tablas...
CREATE POLICY "Control salidas visible para padres y staff" ON control_salidas FOR SELECT USING (
  EXISTS (SELECT 1 FROM alumnos WHERE id = control_salidas.alumno_id AND padre_id = auth.uid())
  OR EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('profesor', 'directora'))
);

CREATE POLICY "Clases extra visibles para todos" ON clases_extracurriculares FOR SELECT USING (true);
CREATE POLICY "Directora gestiona clases extra" ON clases_extracurriculares FOR ALL USING (
  EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol = 'directora')
);

-- ============================================
-- FIN DE LA BASE DE DATOS
-- ============================================
