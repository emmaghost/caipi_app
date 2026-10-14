-- Papás pueden marcar anuncios como leídos (hoy RLS solo deja actualizar al staff).
-- Ejecutar en Supabase → SQL Editor → Run.

ALTER TABLE public.anuncios
  ALTER COLUMN leido_por TYPE TEXT[] USING COALESCE(leido_por::text[], '{}');

ALTER TABLE public.anuncios
  ALTER COLUMN leido_por SET DEFAULT '{}';

CREATE OR REPLACE FUNCTION public.marcar_anuncio_leido(p_anuncio_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_leidos text[];
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  UPDATE public.anuncios
  SET leido_por = CASE
        WHEN COALESCE(leido_por, '{}') @> ARRAY[v_uid] THEN leido_por
        ELSE COALESCE(leido_por, '{}') || v_uid
      END
  WHERE id = p_anuncio_id
  RETURNING leido_por INTO v_leidos;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Anuncio no encontrado';
  END IF;

  RETURN v_leidos;
END;
$$;

GRANT EXECUTE ON FUNCTION public.marcar_anuncio_leido(uuid) TO authenticated;

DROP POLICY IF EXISTS "Padres marcan anuncios leidos" ON public.anuncios;
CREATE POLICY "Padres marcan anuncios leidos"
  ON public.anuncios
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.activo = true AND u.rol = 'padre'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.activo = true AND u.rol = 'padre'
    )
  );

CREATE OR REPLACE FUNCTION public.anuncios_padre_solo_leido()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_rol text;
BEGIN
  SELECT rol INTO v_rol FROM public.usuarios WHERE id = auth.uid();
  IF v_rol = 'padre' THEN
    IF NEW.titulo IS DISTINCT FROM OLD.titulo
       OR NEW.mensaje IS DISTINCT FROM OLD.mensaje
       OR NEW.prioridad IS DISTINCT FROM OLD.prioridad
       OR NEW.fecha_publicacion IS DISTINCT FROM OLD.fecha_publicacion
       OR NEW.creado_por IS DISTINCT FROM OLD.creado_por
       OR NEW.para_todos IS DISTINCT FROM OLD.para_todos
       OR NEW.para_grados IS DISTINCT FROM OLD.para_grados
    THEN
      RAISE EXCEPTION 'Un papá solo puede marcar el anuncio como leído';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_anuncios_padre_solo_leido ON public.anuncios;
CREATE TRIGGER trg_anuncios_padre_solo_leido
  BEFORE UPDATE ON public.anuncios
  FOR EACH ROW
  EXECUTE FUNCTION public.anuncios_padre_solo_leido();
