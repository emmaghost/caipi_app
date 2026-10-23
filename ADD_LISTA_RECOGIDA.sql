-- =============================================================================
-- Lista fija de quién puede recoger a cada niño (máximo 3) + aviso en la entrada
-- Ejecutar en Supabase → SQL Editor
-- La foto de la INE es opcional. El papá no puede editar esta lista.
-- =============================================================================

ALTER TABLE public.personas_autorizadas
  ADD COLUMN IF NOT EXISTS es_lista_fija boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS foto_ine_url text;

ALTER TABLE public.solicitudes_recogida
  ADD COLUMN IF NOT EXISTS persona_autorizada_id uuid,
  ADD COLUMN IF NOT EXISTS quien_nombre text,
  ADD COLUMN IF NOT EXISTS quien_parentesco text,
  ADD COLUMN IF NOT EXISTS requiere_codigo boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.solicitudes_cambio_recogida (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alumno_id uuid NOT NULL REFERENCES public.alumnos(id) ON DELETE CASCADE,
  padre_id uuid NOT NULL,
  mensaje text,
  estado text NOT NULL DEFAULT 'pendiente',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS solicitudes_cambio_recogida_estado_idx
  ON public.solicitudes_cambio_recogida (estado, created_at DESC);

ALTER TABLE public.solicitudes_cambio_recogida ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cambio_recogida_lectura" ON public.solicitudes_cambio_recogida;
CREATE POLICY "cambio_recogida_lectura"
  ON public.solicitudes_cambio_recogida
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "cambio_recogida_padre_inserta" ON public.solicitudes_cambio_recogida;
CREATE POLICY "cambio_recogida_padre_inserta"
  ON public.solicitudes_cambio_recogida
  FOR INSERT TO authenticated
  WITH CHECK (padre_id = auth.uid());

DROP POLICY IF EXISTS "cambio_recogida_staff_actualiza" ON public.solicitudes_cambio_recogida;
CREATE POLICY "cambio_recogida_staff_actualiza"
  ON public.solicitudes_cambio_recogida
  FOR UPDATE TO authenticated
  USING (true);

CREATE OR REPLACE FUNCTION public.es_staff_caipi()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor', 'profesor_admin', 'secretaria')
  );
$$;

CREATE OR REPLACE FUNCTION public.bloquear_lista_fija_si_no_es_staff()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid() AND rol = 'directora'
  ) THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' AND COALESCE(NEW.es_lista_fija, false) THEN
    RAISE EXCEPTION 'La lista de recogida solo la carga la directora';
  END IF;

  IF TG_OP = 'UPDATE' AND COALESCE(OLD.es_lista_fija, false) THEN
    RAISE EXCEPTION 'La lista de recogida solo la cambia la directora';
  END IF;

  IF TG_OP = 'DELETE' AND COALESCE(OLD.es_lista_fija, false) THEN
    RAISE EXCEPTION 'La lista de recogida solo la cambia la directora';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lista_fija_solo_staff ON public.personas_autorizadas;
CREATE TRIGGER trg_lista_fija_solo_staff
  BEFORE INSERT OR UPDATE OR DELETE ON public.personas_autorizadas
  FOR EACH ROW
  EXECUTE FUNCTION public.bloquear_lista_fija_si_no_es_staff();

CREATE OR REPLACE FUNCTION public.max_tres_en_lista_fija()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  total integer;
BEGIN
  IF NOT COALESCE(NEW.es_lista_fija, false) THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO total
  FROM public.personas_autorizadas
  WHERE alumno_id = NEW.alumno_id
    AND es_lista_fija = true
    AND id IS DISTINCT FROM NEW.id;

  IF total >= 3 THEN
    RAISE EXCEPTION 'Cada niño puede tener máximo 3 personas de recogida';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_max_tres_lista_fija ON public.personas_autorizadas;
CREATE TRIGGER trg_max_tres_lista_fija
  BEFORE INSERT OR UPDATE ON public.personas_autorizadas
  FOR EACH ROW
  EXECUTE FUNCTION public.max_tres_en_lista_fija();

-- «No se parece» guarda el estado no_coincide. El check original solo dejaba
-- pendiente, atendida y cancelada.
ALTER TABLE public.solicitudes_recogida
  DROP CONSTRAINT IF EXISTS solicitudes_recogida_estado_check;

ALTER TABLE public.solicitudes_recogida
  ADD CONSTRAINT solicitudes_recogida_estado_check
  CHECK (estado IN ('pendiente', 'atendida', 'cancelada', 'no_coincide'));

NOTIFY pgrst, 'reload schema';
