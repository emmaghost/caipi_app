-- =============================================================================
-- HITOS DEL DESARROLLO — preparar esquema Portage por edad (meses)
-- Ejecutar en Supabase → SQL Editor (una sola vez).
--
-- ⚠️ Borra TODO el catálogo Portage anterior (listas, indicadores, evaluaciones,
--    calificaciones). No inserta los hitos: la carga se hace desde la app.
-- =============================================================================

-- 1) Limpiar datos viejos (orden por dependencias)
DELETE FROM public.portage_resultados;
DELETE FROM public.portage_evaluaciones;
DELETE FROM public.portage_indicadores;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'portage_alumno_listas'
  ) THEN
    DELETE FROM public.portage_alumno_listas;
  END IF;
END $$;

DELETE FROM public.portage_listas;

-- 2) Columnas para catálogo por edad y área
ALTER TABLE public.portage_listas
  ADD COLUMN IF NOT EXISTS meses_edad INTEGER NULL;

COMMENT ON COLUMN public.portage_listas.meses_edad IS
  'Edad en meses del tramo de hitos (3, 6, 9, … 72). NULL = lista sin tramo.';

ALTER TABLE public.portage_indicadores
  ADD COLUMN IF NOT EXISTS area TEXT NULL;

COMMENT ON COLUMN public.portage_indicadores.area IS
  'Área del hito: Motor Grueso, Motor Fino, Cognitivo, Lenguaje, Socialización.';

-- 3) Asignación de listas por alumno (directora elige qué ve cada niño)
CREATE TABLE IF NOT EXISTS public.portage_alumno_listas (
  alumno_id UUID NOT NULL REFERENCES public.alumnos(id) ON DELETE CASCADE,
  lista_id UUID NOT NULL REFERENCES public.portage_listas(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by UUID NULL REFERENCES public.usuarios(id) ON DELETE SET NULL,
  PRIMARY KEY (alumno_id, lista_id)
);

CREATE INDEX IF NOT EXISTS idx_portage_alumno_listas_alumno
  ON public.portage_alumno_listas(alumno_id);

CREATE INDEX IF NOT EXISTS idx_portage_alumno_listas_lista
  ON public.portage_alumno_listas(lista_id);

COMMENT ON TABLE public.portage_alumno_listas IS
  'Listas de hitos asignadas manualmente a cada alumno.';

-- 4) RLS — staff gestiona; padre solo lectura si el niño es suyo y portage_visible_padre
ALTER TABLE public.portage_alumno_listas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "portage_alumno_listas_staff" ON public.portage_alumno_listas;
CREATE POLICY "portage_alumno_listas_staff" ON public.portage_alumno_listas
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
        AND u.activo = true
    )
  );

DROP POLICY IF EXISTS "portage_alumno_listas_padre_lectura" ON public.portage_alumno_listas;
CREATE POLICY "portage_alumno_listas_padre_lectura" ON public.portage_alumno_listas
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.alumnos a
      WHERE a.id = portage_alumno_listas.alumno_id
        AND a.padre_id = auth.uid()
        AND a.portage_visible_padre = true
    )
  );

-- Verificación
SELECT
  (SELECT count(*) FROM public.portage_listas) AS listas,
  (SELECT count(*) FROM public.portage_indicadores) AS indicadores,
  (SELECT count(*) FROM public.portage_evaluaciones) AS evaluaciones,
  (SELECT count(*) FROM public.portage_resultados) AS calificaciones;
