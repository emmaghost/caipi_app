-- =============================================================================
-- Anuncios: alinear columnas + asegurar que se puedan publicar
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================

ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS fecha_publicacion TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS para_todos BOOLEAN DEFAULT true;
ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS para_grados UUID[];
ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS prioridad TEXT DEFAULT 'normal';
ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS creado_por UUID REFERENCES public.usuarios(id);
ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS leido_por TEXT[] DEFAULT '{}';
ALTER TABLE public.anuncios
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Migrar columnas viejas si existían (fecha / grados)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'anuncios' AND column_name = 'fecha'
  ) THEN
    EXECUTE $u$
      UPDATE public.anuncios
      SET fecha_publicacion = COALESCE(fecha_publicacion, fecha::timestamptz, NOW())
      WHERE fecha_publicacion IS NULL
         OR fecha_publicacion < COALESCE(fecha::timestamptz, fecha_publicacion)
    $u$;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'anuncios' AND column_name = 'grados'
  ) THEN
    BEGIN
      EXECUTE $u$
        UPDATE public.anuncios a
        SET para_grados = COALESCE(
          a.para_grados,
          (
            SELECT array_agg(DISTINCT v::uuid)
            FROM unnest(COALESCE(a.grados::text[], '{}'::text[])) AS v
            WHERE v ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          )
        )
        WHERE (a.para_grados IS NULL OR cardinality(a.para_grados) = 0)
          AND a.grados IS NOT NULL
      $u$;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'No se pudo migrar grados → para_grados: %', SQLERRM;
    END;
  END IF;
END $$;

UPDATE public.anuncios
SET fecha_publicacion = COALESCE(fecha_publicacion, NOW())
WHERE fecha_publicacion IS NULL;

UPDATE public.anuncios
SET para_todos = COALESCE(para_todos, true)
WHERE para_todos IS NULL;

UPDATE public.anuncios
SET prioridad = COALESCE(NULLIF(prioridad, ''), 'normal')
WHERE prioridad IS NULL OR prioridad = '';

-- RLS: staff gestiona; todos autenticados leen
ALTER TABLE public.anuncios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ver anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Todos pueden ver anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Gestionar anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Directora gestiona anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Directora puede insertar anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Directora puede actualizar anuncios" ON public.anuncios;

CREATE POLICY "Ver anuncios"
  ON public.anuncios FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Gestionar anuncios"
  ON public.anuncios FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin')
        AND u.activo = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin')
        AND u.activo = true
    )
  );

ALTER TABLE public.anuncios REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'anuncios'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.anuncios;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
