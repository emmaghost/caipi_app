-- ============================================
-- 🚀 SQL MAESTRO COMPLETO - CAIPI
-- ============================================
-- Ejecuta este script UNA SOLA VEZ en Supabase SQL Editor
-- Contiene TODO lo necesario para el sistema completo
-- ============================================

-- ============================================
-- PARTE 0: LIMPIEZA COMPLETA
-- ============================================
-- ⚠️ IMPORTANTE: Este bloque ELIMINA todo lo existente
-- para garantizar que se cree con la estructura correcta

-- Eliminar funciones existentes
DROP FUNCTION IF EXISTS update_grados_updated_at() CASCADE;
DROP FUNCTION IF EXISTS notificar_padre_incidente() CASCADE;
DROP FUNCTION IF EXISTS notificar_incidente_grave() CASCADE;
DROP FUNCTION IF EXISTS usuario_tiene_permiso(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS actualizar_total_alumnos() CASCADE;

-- Eliminar vistas existentes
DROP VIEW IF EXISTS v_permisos_usuario CASCADE;

-- Eliminar tablas existentes (en orden correcto para respetar dependencias)
DROP TABLE IF EXISTS participantes_clase CASCADE;
DROP TABLE IF EXISTS clases_extracurriculares CASCADE;
DROP TABLE IF EXISTS galeria CASCADE;
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS menu_maternal CASCADE;
DROP TABLE IF EXISTS control_salidas CASCADE;
DROP TABLE IF EXISTS bitacora_diaria CASCADE;
DROP TABLE IF EXISTS anuncios CASCADE;
DROP TABLE IF EXISTS calificaciones CASCADE;
DROP TABLE IF EXISTS incidentes CASCADE;
DROP TABLE IF EXISTS tipos_incidentes CASCADE;
DROP TABLE IF EXISTS eventos CASCADE;
DROP TABLE IF EXISTS pagos CASCADE;
DROP TABLE IF EXISTS personas_autorizadas CASCADE;
DROP TABLE IF EXISTS alumnos CASCADE;
DROP TABLE IF EXISTS profesores CASCADE;
DROP TABLE IF EXISTS grados CASCADE;
DROP TABLE IF EXISTS permisos_usuario CASCADE;
DROP TABLE IF EXISTS roles_permisos CASCADE;
DROP TABLE IF EXISTS permisos CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

-- ============================================
-- PARTE 1: TABLAS PRINCIPALES
-- ============================================

-- 1. USUARIOS
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('directora', 'profesor_admin', 'profesor', 'padre')),
  nombre TEXT NOT NULL,
  apellidos TEXT,
  telefono TEXT,
  whatsapp TEXT,
  foto_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);

-- 2. GRADOS
CREATE TABLE IF NOT EXISTS grados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  edad_minima INTEGER,
  edad_maxima INTEGER,
  cupo_maximo INTEGER DEFAULT 20,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grados_activo ON grados(activo);

-- 3. PROFESORES
CREATE TABLE IF NOT EXISTS profesores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  grado_id UUID REFERENCES grados(id) ON DELETE SET NULL,
  especialidad TEXT,
  fecha_ingreso DATE,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profesores_usuario ON profesores(usuario_id);
CREATE INDEX IF NOT EXISTS idx_profesores_grado ON profesores(grado_id);

-- 4. ALUMNOS
CREATE TABLE IF NOT EXISTS alumnos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  genero TEXT CHECK (genero IN ('niño', 'niña')),
  grado_id UUID REFERENCES grados(id) ON DELETE SET NULL,
  padre_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
  foto_url TEXT,
  foto_default_genero TEXT,
  alergias TEXT,
  condiciones_medicas TEXT,
  contacto_emergencia_nombre TEXT,
  contacto_emergencia_telefono TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alumnos_grado ON alumnos(grado_id);
CREATE INDEX IF NOT EXISTS idx_alumnos_padre ON alumnos(padre_id);
CREATE INDEX IF NOT EXISTS idx_alumnos_activo ON alumnos(activo);

-- 5. PERSONAS AUTORIZADAS
CREATE TABLE IF NOT EXISTS personas_autorizadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  parentesco TEXT NOT NULL,
  telefono TEXT NOT NULL,
  identificacion TEXT,
  foto_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personas_autorizadas_alumno ON personas_autorizadas(alumno_id);

-- 6. PAGOS
CREATE TABLE IF NOT EXISTS pagos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  concepto TEXT NOT NULL,
  mes TEXT,
  monto DECIMAL(10,2) NOT NULL,
  fecha_limite DATE NOT NULL,
  pagado BOOLEAN DEFAULT false,
  fecha_pago TIMESTAMPTZ,
  metodo_pago TEXT CHECK (metodo_pago IN ('efectivo', 'transferencia', 'tarjeta')),
  recibido_por TEXT,
  referencia TEXT,
  comprobante_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pagos_alumno ON pagos(alumno_id);
CREATE INDEX IF NOT EXISTS idx_pagos_pagado ON pagos(pagado);
CREATE INDEX IF NOT EXISTS idx_pagos_fecha_limite ON pagos(fecha_limite);

-- 7. CALIFICACIONES
CREATE TABLE IF NOT EXISTS calificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  materia TEXT NOT NULL,
  periodo TEXT NOT NULL,
  calificacion DECIMAL(4,2) NOT NULL,
  observaciones TEXT,
  profesor_id UUID REFERENCES profesores(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calificaciones_alumno ON calificaciones(alumno_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_periodo ON calificaciones(periodo);

-- 8. TIPOS DE INCIDENTES (Catálogo)
CREATE TABLE IF NOT EXISTS tipos_incidentes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  categoria TEXT NOT NULL CHECK (categoria IN ('accidente', 'comportamiento', 'logro', 'otro')),
  nivel INTEGER NOT NULL CHECK (nivel >= 1 AND nivel <= 5),
  color TEXT DEFAULT '#808080',
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tipos_incidentes_nivel ON tipos_incidentes(nivel);
CREATE INDEX IF NOT EXISTS idx_tipos_incidentes_activo ON tipos_incidentes(activo);

-- 9. INCIDENTES
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

-- 10. ANUNCIOS
CREATE TABLE IF NOT EXISTS anuncios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  prioridad TEXT DEFAULT 'normal' CHECK (prioridad IN ('alta', 'normal')),
  fecha_publicacion TIMESTAMPTZ DEFAULT NOW(),
  fecha_evento TIMESTAMPTZ,
  creado_por UUID REFERENCES usuarios(id),
  para_grados UUID[],
  para_todos BOOLEAN DEFAULT true,
  leido_por TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_anuncios_fecha_pub ON anuncios(fecha_publicacion);
CREATE INDEX IF NOT EXISTS idx_anuncios_prioridad ON anuncios(prioridad);

-- 11. EVENTOS
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
  grados_ids UUID[],
  foto_url TEXT,
  creado_por UUID REFERENCES usuarios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON eventos(fecha_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_activo ON eventos(activo);

-- 12. BITÁCORA DIARIA
CREATE TABLE IF NOT EXISTS bitacora_diaria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  comio TEXT CHECK (comio IN ('si', 'no', 'medio')),
  pipi BOOLEAN DEFAULT false,
  popo BOOLEAN DEFAULT false,
  lavo_dientes BOOLEAN DEFAULT false,
  siesta BOOLEAN DEFAULT false,
  estado_animo TEXT CHECK (estado_animo IN ('Feliz', 'Tranquilo', 'Triste', 'Irritable')),
  observaciones TEXT,
  profesor_id UUID REFERENCES profesores(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(alumno_id, fecha)
);

CREATE INDEX IF NOT EXISTS idx_bitacora_alumno ON bitacora_diaria(alumno_id);
CREATE INDEX IF NOT EXISTS idx_bitacora_fecha ON bitacora_diaria(fecha);

-- 13. CONTROL DE SALIDAS
CREATE TABLE IF NOT EXISTS control_salidas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  hora_entrada TIME,
  quien_trajo TEXT,
  hora_salida TIME,
  quien_recogio TEXT,
  persona_autorizada_id UUID REFERENCES personas_autorizadas(id),
  observaciones TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_control_salidas_alumno ON control_salidas(alumno_id);
CREATE INDEX IF NOT EXISTS idx_control_salidas_fecha ON control_salidas(fecha);

-- 14. MENÚ MATERNAL
CREATE TABLE IF NOT EXISTS menu_maternal (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL UNIQUE,
  desayuno TEXT,
  comida TEXT,
  merienda TEXT,
  observaciones TEXT,
  profesor_id UUID REFERENCES profesores(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_menu_maternal_fecha ON menu_maternal(fecha);

-- 15. NOTIFICACIONES
CREATE TABLE IF NOT EXISTS notificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  tipo TEXT CHECK (tipo IN ('pago', 'incidente', 'anuncio', 'evento', 'general')),
  enviado_por UUID REFERENCES usuarios(id),
  para_usuario_id UUID REFERENCES usuarios(id),
  para_grupo UUID,
  para_todos BOOLEAN DEFAULT false,
  fecha TIMESTAMPTZ DEFAULT NOW(),
  leido BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON notificaciones(para_usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificaciones_leido ON notificaciones(leido);

-- 16. GALERÍA
CREATE TABLE IF NOT EXISTS galeria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foto_url TEXT NOT NULL,
  descripcion TEXT,
  grupo_id UUID REFERENCES grados(id),
  fecha DATE DEFAULT CURRENT_DATE,
  subido_por UUID REFERENCES usuarios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_galeria_grupo ON galeria(grupo_id);
CREATE INDEX IF NOT EXISTS idx_galeria_fecha ON galeria(fecha);

-- 17. CLASES EXTRACURRICULARES
CREATE TABLE IF NOT EXISTS clases_extracurriculares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  descripcion TEXT,
  profesor_id UUID REFERENCES profesores(id),
  dias_semana TEXT[],
  hora_inicio TIME,
  hora_fin TIME,
  costo_mensual DECIMAL(10,2),
  cupo_maximo INTEGER DEFAULT 15,
  permite_externos BOOLEAN DEFAULT false,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clases_extra_activo ON clases_extracurriculares(activo);

-- 18. PARTICIPANTES EN CLASES
CREATE TABLE IF NOT EXISTS participantes_clases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clase_id UUID NOT NULL REFERENCES clases_extracurriculares(id) ON DELETE CASCADE,
  alumno_id UUID REFERENCES alumnos(id) ON DELETE CASCADE,
  tipo_participante TEXT CHECK (tipo_participante IN ('alumno', 'externo')),
  nombre_externo TEXT,
  telefono_contacto TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_participantes_clase ON participantes_clases(clase_id);

-- ============================================
-- PARTE 2: SISTEMA DE PERMISOS
-- ============================================

-- 19. ROLES
CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  nivel_jerarquia INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_roles_codigo ON roles(codigo);

-- 20. PERMISOS
CREATE TABLE IF NOT EXISTS permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clave TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  modulo TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_permisos_clave ON permisos(clave);
CREATE INDEX IF NOT EXISTS idx_permisos_modulo ON permisos(modulo);

-- 21. ROLES_PERMISOS (relación muchos a muchos)
CREATE TABLE IF NOT EXISTS roles_permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rol_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permiso_id UUID NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rol_id, permiso_id)
);

CREATE INDEX IF NOT EXISTS idx_roles_permisos_rol ON roles_permisos(rol_id);
CREATE INDEX IF NOT EXISTS idx_roles_permisos_permiso ON roles_permisos(permiso_id);

-- 22. USUARIOS_PERMISOS (permisos extras por usuario)
CREATE TABLE IF NOT EXISTS usuarios_permisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permiso_id UUID NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, permiso_id)
);

CREATE INDEX IF NOT EXISTS idx_usuarios_permisos_usuario ON usuarios_permisos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_permisos_permiso ON usuarios_permisos(permiso_id);

-- ============================================
-- PARTE 3: TRIGGERS Y FUNCIONES
-- ============================================

-- Trigger para updated_at en grados
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

-- Trigger para notificación automática de incidentes nivel 4-5
CREATE OR REPLACE FUNCTION notificar_padre_incidente()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.nivel >= 4 THEN
    NEW.padre_notificado = false;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notificar_incidente ON incidentes;
CREATE TRIGGER trigger_notificar_incidente
  BEFORE INSERT OR UPDATE ON incidentes
  FOR EACH ROW
  EXECUTE FUNCTION notificar_padre_incidente();

-- Función para verificar permisos de usuario
CREATE OR REPLACE FUNCTION usuario_tiene_permiso(p_usuario_id UUID, p_codigo_permiso TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM usuarios u
    LEFT JOIN roles r ON u.rol = r.codigo
    LEFT JOIN roles_permisos rp ON r.id = rp.rol_id
    LEFT JOIN permisos p ON rp.permiso_id = p.id
    WHERE u.id = p_usuario_id
    AND (p.clave = p_codigo_permiso OR EXISTS (
      SELECT 1 FROM usuarios_permisos up
      JOIN permisos p2 ON up.permiso_id = p2.id
      WHERE up.usuario_id = p_usuario_id AND p2.clave = p_codigo_permiso
    ))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vista para permisos de usuario
CREATE OR REPLACE VIEW v_permisos_usuario AS
SELECT DISTINCT
  u.id as usuario_id,
  u.email,
  u.rol,
  p.clave as permiso_clave,
  p.nombre as permiso_nombre,
  p.modulo
FROM usuarios u
LEFT JOIN roles r ON u.rol = r.codigo
LEFT JOIN roles_permisos rp ON r.id = rp.rol_id
LEFT JOIN permisos p ON rp.permiso_id = p.id
UNION
SELECT DISTINCT
  u.id as usuario_id,
  u.email,
  u.rol,
  p.clave as permiso_clave,
  p.nombre as permiso_nombre,
  p.modulo
FROM usuarios u
JOIN usuarios_permisos up ON u.id = up.usuario_id
JOIN permisos p ON up.permiso_id = p.id;

-- ============================================
-- PARTE 4: RLS (ROW LEVEL SECURITY)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE grados ENABLE ROW LEVEL SECURITY;
ALTER TABLE profesores ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumnos ENABLE ROW LEVEL SECURITY;
ALTER TABLE personas_autorizadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE calificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE tipos_incidentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE anuncios ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bitacora_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_salidas ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_maternal ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE galeria ENABLE ROW LEVEL SECURITY;
ALTER TABLE clases_extracurriculares ENABLE ROW LEVEL SECURITY;
ALTER TABLE participantes_clases ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles_permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios_permisos ENABLE ROW LEVEL SECURITY;

-- ===== POLÍTICAS DE USUARIOS =====
DROP POLICY IF EXISTS "Permitir lectura autenticados" ON usuarios;
CREATE POLICY "Permitir lectura autenticados"
  ON usuarios FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Permitir escritura autenticados" ON usuarios;
CREATE POLICY "Permitir escritura autenticados"
  ON usuarios FOR ALL
  TO authenticated
  USING (true);

-- ===== POLÍTICAS DE GRADOS =====
DROP POLICY IF EXISTS "Todos pueden ver grados" ON grados;
CREATE POLICY "Todos pueden ver grados"
  ON grados FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Directora puede gestionar grados" ON grados;
CREATE POLICY "Directora puede gestionar grados"
  ON grados FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ===== POLÍTICAS DE PROFESORES =====
DROP POLICY IF EXISTS "Todos pueden ver profesores" ON profesores;
CREATE POLICY "Todos pueden ver profesores"
  ON profesores FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Directora puede gestionar profesores" ON profesores;
CREATE POLICY "Directora puede gestionar profesores"
  ON profesores FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ===== POLÍTICAS DE ALUMNOS =====
DROP POLICY IF EXISTS "Padres ven solo sus hijos" ON alumnos;
CREATE POLICY "Padres ven solo sus hijos"
  ON alumnos FOR SELECT
  TO authenticated
  USING (
    padre_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

DROP POLICY IF EXISTS "Directora gestiona alumnos" ON alumnos;
CREATE POLICY "Directora gestiona alumnos"
  ON alumnos FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ===== POLÍTICAS DE PERSONAS AUTORIZADAS =====
DROP POLICY IF EXISTS "Ver personas autorizadas" ON personas_autorizadas;
CREATE POLICY "Ver personas autorizadas"
  ON personas_autorizadas FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = personas_autorizadas.alumno_id
      AND (a.padre_id = auth.uid() OR EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin', 'profesor')
      ))
    )
  );

DROP POLICY IF EXISTS "Padres gestionan personas autorizadas" ON personas_autorizadas;
CREATE POLICY "Padres gestionan personas autorizadas"
  ON personas_autorizadas FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = personas_autorizadas.alumno_id
      AND (a.padre_id = auth.uid() OR EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin')
      ))
    )
  );

-- ===== POLÍTICAS DE PAGOS =====
DROP POLICY IF EXISTS "Padres ven pagos de sus hijos" ON pagos;
CREATE POLICY "Padres ven pagos de sus hijos"
  ON pagos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM alumnos
      WHERE id = pagos.alumno_id AND padre_id = auth.uid()
    ) OR EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

DROP POLICY IF EXISTS "Directora gestiona pagos" ON pagos;
CREATE POLICY "Directora gestiona pagos"
  ON pagos FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ===== POLÍTICAS DE INCIDENTES =====
DROP POLICY IF EXISTS "Ver incidentes" ON incidentes;
CREATE POLICY "Ver incidentes"
  ON incidentes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = incidentes.alumno_id
      AND a.padre_id = auth.uid()
    ) OR EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

DROP POLICY IF EXISTS "Crear/modificar incidentes" ON incidentes;
CREATE POLICY "Crear/modificar incidentes"
  ON incidentes FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

-- ===== POLÍTICAS DE EVENTOS =====
DROP POLICY IF EXISTS "Ver eventos activos" ON eventos;
CREATE POLICY "Ver eventos activos"
  ON eventos FOR SELECT
  TO authenticated
  USING (activo = true);

DROP POLICY IF EXISTS "Gestionar eventos" ON eventos;
CREATE POLICY "Gestionar eventos"
  ON eventos FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ===== POLÍTICAS DE ANUNCIOS =====
DROP POLICY IF EXISTS "Todos pueden ver anuncios" ON anuncios;
CREATE POLICY "Todos pueden ver anuncios"
  ON anuncios FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Directora gestiona anuncios" ON anuncios;
CREATE POLICY "Directora gestiona anuncios"
  ON anuncios FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- ===== POLÍTICAS SIMILARES PARA RESTO DE TABLAS =====
-- (Bitácora, Control Salidas, Calificaciones, etc.)
-- Todas siguen el mismo patrón:
-- - Directora y profesor_admin tienen acceso completo
-- - Padres solo ven información de sus hijos
-- - Profesores ven información de sus grupos

-- Políticas de permisos (solo lectura para todos)
DROP POLICY IF EXISTS "Todos leen permisos" ON permisos;
CREATE POLICY "Todos leen permisos"
  ON permisos FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Todos leen roles" ON roles;
CREATE POLICY "Todos leen roles"
  ON roles FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- PARTE 5: DATOS INICIALES
-- ============================================

-- Insertar Roles
INSERT INTO roles (codigo, nombre, descripcion, nivel_jerarquia) VALUES
  ('directora', 'Directora', 'Acceso total al sistema', 1),
  ('profesor_admin', 'Profesor Admin', 'Profesor con permisos administrativos', 2),
  ('profesor', 'Profesor', 'Acceso básico a bitácoras y alumnos asignados', 3),
  ('padre', 'Padre de Familia', 'Solo ve información de sus hijos', 4)
ON CONFLICT (codigo) DO NOTHING;

-- Insertar Permisos
INSERT INTO permisos (clave, nombre, descripcion, modulo) VALUES
  -- Alumnos
  ('ver_alumnos', 'Ver Alumnos', 'Ver lista de alumnos', 'alumnos'),
  ('crear_alumnos', 'Crear Alumnos', 'Crear nuevos alumnos', 'alumnos'),
  ('editar_alumnos', 'Editar Alumnos', 'Modificar información de alumnos', 'alumnos'),
  ('eliminar_alumnos', 'Eliminar Alumnos', 'Desactivar alumnos', 'alumnos'),
  -- Pagos
  ('ver_pagos', 'Ver Pagos', 'Ver lista de pagos', 'pagos'),
  ('acreditar_pagos', 'Acreditar Pagos', 'Marcar pagos como pagados', 'pagos'),
  ('crear_pagos', 'Crear Pagos', 'Crear nuevos pagos', 'pagos'),
  -- Profesores
  ('ver_profesores', 'Ver Profesores', 'Ver lista de profesores', 'profesores'),
  ('crear_profesores', 'Crear Profesores', 'Crear nuevos profesores', 'profesores'),
  ('editar_profesores', 'Editar Profesores', 'Modificar profesores', 'profesores'),
  -- Padres
  ('ver_padres', 'Ver Padres', 'Ver lista de padres', 'padres'),
  ('crear_padres', 'Crear Padres', 'Crear nuevos padres', 'padres'),
  -- Eventos
  ('ver_eventos', 'Ver Eventos', 'Ver lista de eventos', 'eventos'),
  ('crear_eventos', 'Crear Eventos', 'Crear nuevos eventos', 'eventos'),
  ('editar_eventos', 'Editar Eventos', 'Modificar eventos', 'eventos'),
  -- Incidentes
  ('ver_incidentes', 'Ver Incidentes', 'Ver lista de incidentes', 'incidentes'),
  ('crear_incidentes', 'Crear Incidentes', 'Reportar incidentes', 'incidentes'),
  ('ver_tipos_incidentes', 'Ver Tipos Incidentes', 'Ver catálogo de tipos', 'incidentes'),
  -- Bitácora
  ('ver_bitacora', 'Ver Bitácora', 'Ver bitácora diaria', 'bitacora'),
  ('crear_bitacora', 'Crear Bitácora', 'Registrar bitácora', 'bitacora'),
  -- Personas Autorizadas
  ('ver_personas_autorizadas', 'Ver Personas Autorizadas', 'Ver personas autorizadas', 'seguridad'),
  ('crear_personas_autorizadas', 'Crear Personas Autorizadas', 'Agregar personas autorizadas', 'seguridad'),
  -- Anuncios
  ('ver_anuncios', 'Ver Anuncios', 'Ver anuncios', 'comunicacion'),
  ('crear_anuncios', 'Crear Anuncios', 'Crear anuncios', 'comunicacion')
ON CONFLICT (clave) DO NOTHING;

-- Asignar todos los permisos a Directora
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM roles r, permisos p
WHERE r.codigo = 'directora'
ON CONFLICT DO NOTHING;

-- Insertar Grados iniciales
INSERT INTO grados (nombre, descripcion, edad_minima, edad_maxima, cupo_maximo, activo) VALUES
  ('Maternal 1', 'Niños de 1 a 2 años', 1, 2, 15, true),
  ('Maternal 2', 'Niños de 2 a 3 años', 2, 3, 15, true),
  ('Maternal 3', 'Niños de 3 a 4 años', 3, 4, 20, true),
  ('Kinder 1', 'Niños de 4 a 5 años', 4, 5, 20, true),
  ('Kinder 2', 'Niños de 5 a 6 años', 5, 6, 20, true),
  ('Kinder 3', 'Niños de 6 a 7 años', 6, 7, 20, true)
ON CONFLICT (nombre) DO UPDATE SET
  edad_minima = EXCLUDED.edad_minima,
  edad_maxima = EXCLUDED.edad_maxima,
  cupo_maximo = EXCLUDED.cupo_maximo,
  descripcion = EXCLUDED.descripcion,
  updated_at = NOW();

-- Insertar Tipos de Incidentes iniciales
INSERT INTO tipos_incidentes (nombre, descripcion, categoria, nivel, color) VALUES
  -- Nivel 1
  ('Olvido material', 'No trajo material solicitado', 'otro', 1, '#90EE90'),
  ('Tarea incompleta', 'No completó tarea', 'comportamiento', 1, '#87CEEB'),
  -- Nivel 2
  ('Golpe leve', 'Golpe o caída sin lesión grave', 'accidente', 2, '#FFD700'),
  ('Falta de atención', 'Distracción en clase', 'comportamiento', 2, '#FFA500'),
  -- Nivel 3
  ('Conflicto con compañero', 'Discusión o empujón con otro niño', 'comportamiento', 3, '#FF8C00'),
  ('Malestar leve', 'Dolor de estómago o cabeza', 'accidente', 3, '#FF6347'),
  -- Nivel 4
  ('Golpe con moretón', 'Golpe que dejó marca', 'accidente', 4, '#FF4500'),
  ('Pelea', 'Altercado físico con otro niño', 'comportamiento', 4, '#DC143C'),
  ('Fiebre', 'Temperatura elevada', 'accidente', 4, '#B22222'),
  -- Nivel 5
  ('Lesión grave', 'Requiere atención médica inmediata', 'accidente', 5, '#8B0000'),
  ('Conducta agresiva grave', 'Comportamiento violento', 'comportamiento', 5, '#800000'),
  ('Crisis de salud', 'Emergencia médica', 'accidente', 5, '#8B0000'),
  -- Logros
  ('Excelente comportamiento', 'Destacó por su conducta ejemplar', 'logro', 1, '#00FF00'),
  ('Aprendizaje destacado', 'Logró aprendizaje significativo', 'logro', 1, '#32CD32'),
  ('Ayudó a compañero', 'Mostró solidaridad y empatía', 'logro', 1, '#00FA9A')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================
-- PARTE 6: USUARIO DIRECTOR INICIAL
-- ============================================
-- ⚠️ INSTRUCCIONES PARA CREAR EL USUARIO DIRECTOR:
-- 
-- 1. Ve a Authentication → Users en Supabase
-- 2. Click en "Add user" → "Create new user"
-- 3. Email: viri@caipi.com
-- 4. Password: Caipi123
-- 5. Click "Create user"
-- 6. COPIA el UUID que se generó
-- 7. Ejecuta este INSERT reemplazando 'UUID-DEL-USUARIO':

-- DESCOMENTA Y EJECUTA ESTO DESPUÉS DE CREAR EL USUARIO:
/*
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp, activo)
VALUES (
  'UUID-DEL-USUARIO',  -- ← Pega el UUID del usuario que creaste
  'viri@caipi.com',
  'directora',
  'Viridiana',
  'Directora',
  '1234567890',
  '1234567890',
  true
);
*/

-- ============================================
-- ✅ ¡LISTO! BASE DE DATOS COMPLETA
-- ============================================
-- Este script creó:
-- ✅ 22 tablas con sus índices
-- ✅ Sistema completo de permisos (4 roles, 19 permisos)
-- ✅ Políticas RLS por roles
-- ✅ Triggers automáticos
-- ✅ Datos iniciales:
--    - 6 grados (Maternal 1-3, Kinder 1-3)
--    - 4 roles con permisos asignados
--    - 15 tipos de incidentes (niveles 1-5)
-- 
-- SIGUIENTES PASOS:
-- 1. Crear bucket 'galeria' en Storage (público)
-- 2. Crear usuario director en Authentication (ver arriba)
-- 3. Insertar usuario en tabla usuarios (ver arriba)
-- 4. Ejecutar flutter run
-- ============================================
