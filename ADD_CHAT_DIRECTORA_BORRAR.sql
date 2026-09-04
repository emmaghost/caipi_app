-- Solo la directora puede borrar conversaciones (mensajes caen por CASCADE).
-- Ejecutar en Supabase → SQL Editor

DROP POLICY IF EXISTS "Directora borra conversaciones" ON public.conversaciones;
CREATE POLICY "Directora borra conversaciones"
ON public.conversaciones FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.rol = 'directora'
      AND u.activo = TRUE
  )
);

-- Por si algún entorno no tiene CASCADE al borrar mensajes sueltos:
DROP POLICY IF EXISTS "Directora borra mensajes" ON public.mensajes_chat;
CREATE POLICY "Directora borra mensajes"
ON public.mensajes_chat FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.rol = 'directora'
      AND u.activo = TRUE
  )
);
