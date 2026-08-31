-- Padre en la entrada solicita que le entreguen al niño
-- Ejecutar en Supabase → SQL Editor

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

CREATE TABLE IF NOT EXISTS public.solicitudes_recogida (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id UUID NOT NULL REFERENCES public.alumnos(id) ON DELETE CASCADE,
  padre_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  estado TEXT NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente', 'atendida', 'cancelada')),
  mensaje TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  atendida_at TIMESTAMPTZ,
  atendida_por UUID REFERENCES public.usuarios(id)
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_recogida_estado
  ON public.solicitudes_recogida(estado, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_solicitud_pendiente_por_alumno
  ON public.solicitudes_recogida(alumno_id)
  WHERE estado = 'pendiente';

ALTER TABLE public.solicitudes_recogida REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'solicitudes_recogida'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.solicitudes_recogida;
  END IF;
END $$;

ALTER TABLE public.solicitudes_recogida ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Padre ve sus solicitudes" ON public.solicitudes_recogida;
CREATE POLICY "Padre ve sus solicitudes"
ON public.solicitudes_recogida FOR SELECT TO authenticated
USING (
  padre_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.alumnos a
    WHERE a.id = solicitudes_recogida.alumno_id AND a.padre_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Escuela ve solicitudes" ON public.solicitudes_recogida;
CREATE POLICY "Escuela ve solicitudes"
ON public.solicitudes_recogida FOR SELECT TO authenticated
USING (public.usuario_es_escuela());

DROP POLICY IF EXISTS "Padre crea solicitud" ON public.solicitudes_recogida;
CREATE POLICY "Padre crea solicitud"
ON public.solicitudes_recogida FOR INSERT TO authenticated
WITH CHECK (
  padre_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.alumnos a
    WHERE a.id = alumno_id AND a.padre_id = auth.uid() AND a.activo = TRUE
  )
);

DROP POLICY IF EXISTS "Padre cancela su solicitud" ON public.solicitudes_recogida;
CREATE POLICY "Padre cancela su solicitud"
ON public.solicitudes_recogida FOR UPDATE TO authenticated
USING (padre_id = auth.uid())
WITH CHECK (padre_id = auth.uid());

DROP POLICY IF EXISTS "Escuela atiende solicitud" ON public.solicitudes_recogida;
CREATE POLICY "Escuela atiende solicitud"
ON public.solicitudes_recogida FOR UPDATE TO authenticated
USING (public.usuario_es_escuela());

COMMENT ON TABLE public.solicitudes_recogida IS 'Padre en entrada pide que preparen al niño para salida.';
