-- =============================================================================
-- Chat: permitir rol caja (y secretaria) crear conversaciones y mensajes
-- Error típico: 42501 new row violates RLS on "conversaciones"
-- Ejecutar en Supabase → SQL Editor → Run
-- =============================================================================

-- 1) Función usada por las policies del chat (antes NO incluía caja)
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
      AND u.activo = TRUE
      AND u.rol IN (
        'directora',
        'profesor',
        'profesor_admin',
        'secretaria',
        'caja'
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.usuario_es_escuela(UUID) TO authenticated;

-- 2) Alinear helper nuevo (por si ya lo usan otras policies)
CREATE OR REPLACE FUNCTION public.caipi_es_staff_escuela()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND COALESCE(u.activo, true) = true
      AND u.rol IN (
        'directora',
        'profesor',
        'profesor_admin',
        'secretaria',
        'caja'
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_es_staff_escuela() TO authenticated;

-- 3) Reafirmar policies de conversaciones / mensajes (usan usuario_es_escuela)
DROP POLICY IF EXISTS "Escuela ve conversaciones" ON public.conversaciones;
CREATE POLICY "Escuela ve conversaciones"
ON public.conversaciones FOR SELECT TO authenticated
USING (public.usuario_es_escuela());

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

NOTIFY pgrst, 'reload schema';
