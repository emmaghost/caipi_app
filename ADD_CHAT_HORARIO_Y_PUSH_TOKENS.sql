-- CAIPI: horario del chat escolar + tokens push (FCM)
-- Ejecutar en Supabase → SQL Editor (una vez)

-- ============================================
-- 1. Configuración de horario de chat
-- ============================================
CREATE TABLE IF NOT EXISTS public.config_chat_horario (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  -- Días: 1=lunes … 7=domingo (ISO)
  dias_activos INT[] NOT NULL DEFAULT ARRAY[1,2,3,4,5],
  hora_inicio TIME NOT NULL DEFAULT '08:00',
  hora_fin TIME NOT NULL DEFAULT '16:00',
  zona_horaria TEXT NOT NULL DEFAULT 'America/Mexico_City',
  -- Si true, staff (directora/profesora) puede enviar fuera de horario
  staff_siempre_puede BOOLEAN NOT NULL DEFAULT TRUE,
  mensaje_fuera_horario TEXT NOT NULL DEFAULT
    'El chat está disponible de lunes a viernes de 8:00 a 16:00. Fuera de ese horario escribe mañana o llama a la escuela.',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES public.usuarios(id)
);

INSERT INTO public.config_chat_horario (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.config_chat_horario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS config_chat_horario_select ON public.config_chat_horario;
CREATE POLICY config_chat_horario_select ON public.config_chat_horario
  FOR SELECT TO authenticated
  USING (true);

-- Helper (si aún no existe por otros FIX_*)
CREATE OR REPLACE FUNCTION public.caipi_es_directora_o_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin')
  );
$$;

REVOKE ALL ON FUNCTION public.caipi_es_directora_o_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.caipi_es_directora_o_admin() TO authenticated;

DROP POLICY IF EXISTS config_chat_horario_update ON public.config_chat_horario;
DROP POLICY IF EXISTS config_chat_horario_insert ON public.config_chat_horario;

-- UPSERT desde la app necesita INSERT + UPDATE con WITH CHECK
CREATE POLICY config_chat_horario_insert ON public.config_chat_horario
  FOR INSERT TO authenticated
  WITH CHECK (public.caipi_es_directora_o_admin());

CREATE POLICY config_chat_horario_update ON public.config_chat_horario
  FOR UPDATE TO authenticated
  USING (public.caipi_es_directora_o_admin())
  WITH CHECK (public.caipi_es_directora_o_admin());

-- ============================================
-- 2. Tokens FCM (push)
-- ============================================
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  plataforma TEXT NOT NULL DEFAULT 'android'
    CHECK (plataforma IN ('android', 'ios', 'web')),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (usuario_id, token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_usuario
  ON public.device_tokens(usuario_id) WHERE activo = true;

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_tokens_own ON public.device_tokens;
CREATE POLICY device_tokens_own ON public.device_tokens
  FOR ALL TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- Directora puede leer tokens (para envíos admin / debug)
DROP POLICY IF EXISTS device_tokens_directora_select ON public.device_tokens;
CREATE POLICY device_tokens_directora_select ON public.device_tokens
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.rol = 'directora'
    )
  );

-- ============================================
-- 3. Helper: ¿está abierto el chat ahora?
-- ============================================
CREATE OR REPLACE FUNCTION public.chat_esta_abierto_ahora()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cfg RECORD;
  local_ts TIMESTAMP;
  dow INT;
  t TIME;
BEGIN
  SELECT * INTO cfg FROM public.config_chat_horario WHERE id = 1;
  IF NOT FOUND OR NOT cfg.activo THEN
    RETURN TRUE; -- sin config o desactivado = siempre abierto
  END IF;

  local_ts := timezone(cfg.zona_horaria, now());
  -- ISO: lunes=1 … domingo=7
  dow := EXTRACT(ISODOW FROM local_ts)::INT;
  t := local_ts::TIME;

  IF NOT (dow = ANY (cfg.dias_activos)) THEN
    RETURN FALSE;
  END IF;

  IF t < cfg.hora_inicio OR t >= cfg.hora_fin THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.usuario_puede_enviar_chat(p_usuario_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rol TEXT;
  cfg RECORD;
BEGIN
  SELECT rol INTO v_rol FROM public.usuarios WHERE id = p_usuario_id;
  IF v_rol IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT * INTO cfg FROM public.config_chat_horario WHERE id = 1;
  IF NOT FOUND OR NOT cfg.activo THEN
    RETURN TRUE;
  END IF;

  IF cfg.staff_siempre_puede AND v_rol IN ('directora', 'profesor', 'profesor_admin') THEN
    RETURN TRUE;
  END IF;

  RETURN public.chat_esta_abierto_ahora();
END;
$$;

GRANT EXECUTE ON FUNCTION public.chat_esta_abierto_ahora() TO authenticated;
GRANT EXECUTE ON FUNCTION public.usuario_puede_enviar_chat(UUID) TO authenticated;
