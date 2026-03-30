-- ============================================
-- 🔧 SISTEMA DE QR TEMPORAL PARA RECOGER NIÑOS
-- ============================================
-- Este script crea:
-- 1. Tabla para QR temporales (un solo uso)
-- 2. QR permanente para padres
-- 3. Función para generar códigos únicos
-- 4. Función para validar QR
-- ============================================

-- 1. AGREGAR QR PERMANENTE A USUARIOS
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'usuarios' AND column_name = 'qr_permanente'
  ) THEN
    ALTER TABLE usuarios ADD COLUMN qr_permanente TEXT UNIQUE;
    COMMENT ON COLUMN usuarios.qr_permanente IS 'Código QR permanente del padre para identificarse';
  END IF;
END $$;

-- Generar QR para usuarios existentes (padres)
UPDATE usuarios 
SET qr_permanente = 'QR-PADRE-' || SUBSTRING(id::TEXT, 1, 8) || '-' || TO_CHAR(NOW(), 'YYYYMMDD')
WHERE rol = 'padre' AND qr_permanente IS NULL;

-- 2. CREAR TABLA DE QR TEMPORALES
CREATE TABLE IF NOT EXISTS qr_temporales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT UNIQUE NOT NULL,
  persona_autorizada_id UUID NOT NULL REFERENCES personas_autorizadas(id) ON DELETE CASCADE,
  alumno_id UUID NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
  generado_por UUID REFERENCES usuarios(id),
  fecha_generacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_expiracion TIMESTAMPTZ NOT NULL,
  usado BOOLEAN DEFAULT FALSE,
  fecha_uso TIMESTAMPTZ,
  usado_por UUID REFERENCES usuarios(id),
  activo BOOLEAN DEFAULT TRUE,
  notas TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_qr_temporales_codigo ON qr_temporales(codigo) WHERE activo = TRUE AND usado = FALSE;
CREATE INDEX IF NOT EXISTS idx_qr_temporales_persona ON qr_temporales(persona_autorizada_id);
CREATE INDEX IF NOT EXISTS idx_qr_temporales_alumno ON qr_temporales(alumno_id);
CREATE INDEX IF NOT EXISTS idx_qr_temporales_expiracion ON qr_temporales(fecha_expiracion) WHERE activo = TRUE;

COMMENT ON TABLE qr_temporales IS 'QR de un solo uso para que personas autorizadas recojan niños';
COMMENT ON COLUMN qr_temporales.codigo IS 'Código QR único (8 caracteres alfanuméricos)';
COMMENT ON COLUMN qr_temporales.usado IS 'TRUE si el QR ya fue escaneado';
COMMENT ON COLUMN qr_temporales.activo IS 'FALSE si el QR fue cancelado';

-- 3. FUNCIÓN: Generar código QR único (v_codigo evita ambigüedad con columna codigo)
CREATE OR REPLACE FUNCTION generar_codigo_qr()
RETURNS TEXT AS $$
DECLARE
  v_codigo TEXT;
  existe BOOLEAN;
BEGIN
  LOOP
    -- Generar código aleatorio de 8 caracteres (letras mayúsculas y números)
    v_codigo := UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8));
    
    -- Verificar si ya existe (calificar tabla para evitar ambigüedad)
    SELECT EXISTS(SELECT 1 FROM qr_temporales WHERE qr_temporales.codigo = v_codigo) INTO existe;
    
    -- Si no existe, salir del loop
    EXIT WHEN NOT existe;
  END LOOP;
  
  RETURN v_codigo;
END;
$$ LANGUAGE plpgsql;

-- 4. FUNCIÓN: Validar y usar QR temporal
CREATE OR REPLACE FUNCTION validar_qr_temporal(
  p_codigo TEXT,
  p_usuario_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_qr RECORD;
  v_resultado JSON;
BEGIN
  -- Buscar el QR
  SELECT * INTO v_qr
  FROM qr_temporales
  WHERE codigo = p_codigo
    AND activo = TRUE
    AND usado = FALSE
    AND fecha_expiracion > NOW();
  
  -- Si no existe o ya expiró
  IF NOT FOUND THEN
    v_resultado := JSON_BUILD_OBJECT(
      'valido', FALSE,
      'mensaje', 'QR inválido, usado o expirado'
    );
    RETURN v_resultado;
  END IF;
  
  -- Marcar como usado
  UPDATE qr_temporales
  SET usado = TRUE,
      fecha_uso = NOW(),
      usado_por = p_usuario_id
  WHERE id = v_qr.id;
  
  -- Obtener información del alumno
  SELECT JSON_BUILD_OBJECT(
    'valido', TRUE,
    'mensaje', 'QR válido',
    'alumno_id', v_qr.alumno_id,
    'persona_autorizada_id', v_qr.persona_autorizada_id
  ) INTO v_resultado;
  
  RETURN v_resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. FUNCIÓN: Limpiar QR expirados (ejecutar diariamente)
CREATE OR REPLACE FUNCTION limpiar_qr_expirados()
RETURNS INTEGER AS $$
DECLARE
  v_eliminados INTEGER;
BEGIN
  WITH deleted AS (
    DELETE FROM qr_temporales
    WHERE fecha_expiracion < NOW() - INTERVAL '7 days'
    RETURNING *
  )
  SELECT COUNT(*) INTO v_eliminados FROM deleted;
  
  RETURN v_eliminados;
END;
$$ LANGUAGE plpgsql;

-- 6. RLS POLICIES PARA QR TEMPORALES
ALTER TABLE qr_temporales ENABLE ROW LEVEL SECURITY;

-- Los padres pueden ver sus QR temporales
DROP POLICY IF EXISTS "Padres ven sus QR temporales" ON qr_temporales;
CREATE POLICY "Padres ven sus QR temporales" ON qr_temporales
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = qr_temporales.alumno_id
        AND a.padre_id = auth.uid()
    )
  );

-- Los padres pueden crear QR temporales para sus hijos
DROP POLICY IF EXISTS "Padres crean QR temporales" ON qr_temporales;
CREATE POLICY "Padres crean QR temporales" ON qr_temporales
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM alumnos a
      WHERE a.id = qr_temporales.alumno_id
        AND a.padre_id = auth.uid()
    )
  );

-- Directora puede ver y gestionar todos los QR
DROP POLICY IF EXISTS "Directora gestiona QR temporales" ON qr_temporales;
CREATE POLICY "Directora gestiona QR temporales" ON qr_temporales
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid() AND u.rol = 'directora'
    )
  );

-- Profesores pueden validar QR
DROP POLICY IF EXISTS "Profesores validan QR temporales" ON qr_temporales;
CREATE POLICY "Profesores validan QR temporales" ON qr_temporales
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM usuarios u
      WHERE u.id = auth.uid() AND u.rol IN ('profesor', 'directora')
    )
  );

-- ============================================
-- ✅ LISTO
-- ============================================

/*
SISTEMA DE QR:

1. QR PERMANENTE (Padres):
   - Código único por padre
   - Nunca expira
   - Para identificarse al recoger

2. QR TEMPORAL (Personas Autorizadas):
   - Código de 8 caracteres
   - Válido por tiempo limitado
   - Un solo uso
   - Se genera cuando el padre autoriza a alguien

FLUJO:
1. Padre genera QR temporal para persona autorizada
2. QR válido por X horas (ej: 24 horas)
3. Persona autorizada lo usa para recoger al niño
4. Profesor escanea y valida
5. QR se marca como "usado"
6. QR no puede usarse de nuevo

USO EN LA APP:
- Padre: "Generar QR para [Persona]"
- Sistema: Genera código + muestra QR
- Padre: Comparte QR (WhatsApp, screenshot, etc.)
- Profesor: Escanea QR
- Sistema: Valida y marca como usado
*/
