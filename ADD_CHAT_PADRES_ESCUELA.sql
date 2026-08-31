-- Chat in-app: padre ↔ escuela (1 conversación por padre)
-- Ejecutar en Supabase → SQL Editor (Run)

-- ============================================
-- 1. TABLAS
-- ============================================

CREATE TABLE IF NOT EXISTS public.conversaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  padre_id UUID NOT NULL UNIQUE REFERENCES public.usuarios(id) ON DELETE CASCADE,
  ultimo_mensaje TEXT,
  ultimo_mensaje_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversaciones_padre ON public.conversaciones(padre_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_ultimo ON public.conversaciones(ultimo_mensaje_at DESC NULLS LAST);

CREATE TABLE IF NOT EXISTS public.mensajes_chat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversacion_id UUID NOT NULL REFERENCES public.conversaciones(id) ON DELETE CASCADE,
  remitente_id UUID NOT NULL REFERENCES public.usuarios(id),
  contenido TEXT NOT NULL CHECK (char_length(trim(contenido)) > 0),
  leido BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mensajes_chat_conv ON public.mensajes_chat(conversacion_id, created_at);
CREATE INDEX IF NOT EXISTS idx_mensajes_chat_no_leidos ON public.mensajes_chat(conversacion_id, leido)
  WHERE leido = FALSE;

-- ============================================
-- 2. TRIGGER: actualizar preview en conversación
-- ============================================

CREATE OR REPLACE FUNCTION public.actualizar_conversacion_ultimo_mensaje()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.conversaciones
  SET
    ultimo_mensaje = NEW.contenido,
    ultimo_mensaje_at = NEW.created_at,
    updated_at = NOW()
  WHERE id = NEW.conversacion_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mensajes_chat_actualizar_conv ON public.mensajes_chat;
CREATE TRIGGER trg_mensajes_chat_actualizar_conv
  AFTER INSERT ON public.mensajes_chat
  FOR EACH ROW
  EXECUTE FUNCTION public.actualizar_conversacion_ultimo_mensaje();

-- ============================================
-- 3. REALTIME
-- ============================================

ALTER TABLE public.mensajes_chat REPLICA IDENTITY FULL;
ALTER TABLE public.conversaciones REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'mensajes_chat'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.mensajes_chat;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'conversaciones'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversaciones;
  END IF;
END $$;

-- ============================================
-- 4. RLS
-- ============================================

ALTER TABLE public.conversaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes_chat ENABLE ROW LEVEL SECURITY;

-- Helper: ¿usuario es staff de la escuela?
CREATE OR REPLACE FUNCTION public.usuario_es_escuela(p_uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = p_uid
      AND u.rol IN ('directora', 'profesor', 'profesor_admin')
      AND u.activo = TRUE
  );
$$;

-- --- conversaciones ---

DROP POLICY IF EXISTS "Padre ve su conversacion" ON public.conversaciones;
CREATE POLICY "Padre ve su conversacion"
ON public.conversaciones FOR SELECT TO authenticated
USING (padre_id = auth.uid());

DROP POLICY IF EXISTS "Escuela ve conversaciones" ON public.conversaciones;
CREATE POLICY "Escuela ve conversaciones"
ON public.conversaciones FOR SELECT TO authenticated
USING (public.usuario_es_escuela());

DROP POLICY IF EXISTS "Padre crea su conversacion" ON public.conversaciones;
CREATE POLICY "Padre crea su conversacion"
ON public.conversaciones FOR INSERT TO authenticated
WITH CHECK (
  padre_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.rol = 'padre' AND u.activo = TRUE
  )
);

DROP POLICY IF EXISTS "Escuela crea conversacion" ON public.conversaciones;
CREATE POLICY "Escuela crea conversacion"
ON public.conversaciones FOR INSERT TO authenticated
WITH CHECK (public.usuario_es_escuela());

DROP POLICY IF EXISTS "Participantes actualizan conversacion" ON public.conversaciones;
CREATE POLICY "Participantes actualizan conversacion"
ON public.conversaciones FOR UPDATE TO authenticated
USING (
  padre_id = auth.uid() OR public.usuario_es_escuela()
);

-- --- mensajes_chat ---

DROP POLICY IF EXISTS "Participantes ven mensajes" ON public.mensajes_chat;
CREATE POLICY "Participantes ven mensajes"
ON public.mensajes_chat FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.conversaciones c
    WHERE c.id = mensajes_chat.conversacion_id
      AND (c.padre_id = auth.uid() OR public.usuario_es_escuela())
  )
);

DROP POLICY IF EXISTS "Participantes envian mensajes" ON public.mensajes_chat;
CREATE POLICY "Participantes envian mensajes"
ON public.mensajes_chat FOR INSERT TO authenticated
WITH CHECK (
  remitente_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.conversaciones c
    WHERE c.id = mensajes_chat.conversacion_id
      AND (
        (c.padre_id = auth.uid() AND EXISTS (
          SELECT 1 FROM public.usuarios u
          WHERE u.id = auth.uid() AND u.rol = 'padre'
        ))
        OR public.usuario_es_escuela()
      )
  )
);

DROP POLICY IF EXISTS "Participantes marcan leidos" ON public.mensajes_chat;
CREATE POLICY "Participantes marcan leidos"
ON public.mensajes_chat FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.conversaciones c
    WHERE c.id = mensajes_chat.conversacion_id
      AND (c.padre_id = auth.uid() OR public.usuario_es_escuela())
  )
);

COMMENT ON TABLE public.conversaciones IS 'Chat padre ↔ escuela. Una conversación por padre.';
COMMENT ON TABLE public.mensajes_chat IS 'Mensajes del chat in-app padre ↔ escuela.';
