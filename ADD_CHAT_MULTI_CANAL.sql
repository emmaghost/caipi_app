-- =============================================================================
-- CHAT MULTI-CANAL: padre ↔ directora | padre ↔ profesor (staff_id)
-- Migración segura: conversaciones actuales → canal 'directora'
-- =============================================================================

ALTER TABLE public.conversaciones
  ADD COLUMN IF NOT EXISTS canal TEXT NOT NULL DEFAULT 'directora';

ALTER TABLE public.conversaciones
  ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES public.usuarios(id) ON DELETE SET NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'conversaciones_canal_check'
  ) THEN
    ALTER TABLE public.conversaciones
      ADD CONSTRAINT conversaciones_canal_check
      CHECK (canal IN ('directora', 'profesor'));
  END IF;
END $$;

-- Quitar UNIQUE solo en padre_id (nombre típico de constraint)
DO $$
DECLARE
  cname text;
BEGIN
  SELECT conname INTO cname
  FROM pg_constraint
  WHERE conrelid = 'public.conversaciones'::regclass
    AND contype = 'u'
    AND pg_get_constraintdef(oid) ILIKE '%padre_id%'
    AND pg_get_constraintdef(oid) NOT ILIKE '%canal%'
  LIMIT 1;

  IF cname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.conversaciones DROP CONSTRAINT %I', cname);
  END IF;
END $$;

DROP INDEX IF EXISTS public.uq_conversaciones_padre_canal_staff;
CREATE UNIQUE INDEX uq_conversaciones_padre_canal_staff
  ON public.conversaciones (
    padre_id,
    canal,
    COALESCE(staff_id, '00000000-0000-0000-0000-000000000000'::uuid)
  );

UPDATE public.conversaciones
SET canal = 'directora', staff_id = NULL
WHERE canal IS NULL OR canal = '';

COMMENT ON COLUMN public.conversaciones.canal IS
  'directora = hilo con dirección; profesor = hilo con maestra (staff_id)';
COMMENT ON COLUMN public.conversaciones.staff_id IS
  'Usuario profesor del hilo; NULL cuando canal=directora';

-- Config: quién puede chatear (módulo directora)
CREATE TABLE IF NOT EXISTS public.chat_config (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  padre_puede_directora BOOLEAN NOT NULL DEFAULT true,
  padre_puede_maestra_grupo BOOLEAN NOT NULL DEFAULT true,
  padre_puede_maestra_ingles BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.chat_config (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.chat_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chat_config_lectura" ON public.chat_config;
CREATE POLICY "chat_config_lectura"
ON public.chat_config FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "chat_config_directora" ON public.chat_config;
CREATE POLICY "chat_config_directora"
ON public.chat_config FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.rol = 'directora' AND u.activo = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.rol = 'directora' AND u.activo = true
  )
);
