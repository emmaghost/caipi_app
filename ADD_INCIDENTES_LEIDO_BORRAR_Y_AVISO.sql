-- =============================================================================
-- Incidentes: leído/no leído, borrar (staff) y aviso al papá
-- Ejecutar en Supabase → SQL Editor → Run
-- =============================================================================

ALTER TABLE public.incidentes
  ADD COLUMN IF NOT EXISTS leido_padre boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.incidentes.leido_padre IS
  'Si el papá ya vio el incidente. Staff puede volver a marcarlo como no leído.';

-- Trigger: al crear, marcar que se intentará avisar al papá (push lo dispara la app).
CREATE OR REPLACE FUNCTION public.notificar_incidente_grave()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Siempre se avisa al papá al dar de alta (cualquier nivel).
  IF TG_OP = 'INSERT' AND NEW.padre_notificado IS NOT TRUE THEN
    NEW.padre_notificado := true;
    NEW.fecha_notificacion := COALESCE(NEW.fecha_notificacion, NOW());
  END IF;
  IF NEW.leido_padre IS NULL THEN
    NEW.leido_padre := false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notificar_incidente ON public.incidentes;
CREATE TRIGGER trigger_notificar_incidente
  BEFORE INSERT OR UPDATE ON public.incidentes
  FOR EACH ROW
  EXECUTE FUNCTION public.notificar_incidente_grave();

-- RLS: staff (directora / profesor / profesor_admin, incl. maestra de inglés) gestiona todo.
-- Padres: ven los de sus hijos y pueden actualizar solo leido_padre.

DROP POLICY IF EXISTS "Ver incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Gestionar incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Ver incidentes directora/profesores" ON public.incidentes;
DROP POLICY IF EXISTS "Padres ven incidentes de sus hijos" ON public.incidentes;
DROP POLICY IF EXISTS "Crear/modificar incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Padres pueden ver incidentes de sus hijos" ON public.incidentes;
DROP POLICY IF EXISTS "Directora y profesores pueden ver todos los incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Directora y profesores pueden crear incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Directora y profesores pueden actualizar incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Staff gestiona incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Padres ven incidentes hijos" ON public.incidentes;
DROP POLICY IF EXISTS "Padres marcan leido incidente" ON public.incidentes;

CREATE POLICY "Padres ven incidentes hijos"
  ON public.incidentes FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.alumnos a
      WHERE a.id = incidentes.alumno_id
        AND a.padre_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.alumnos_padres ap
      WHERE ap.alumno_id = incidentes.alumno_id
        AND ap.padre_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
    )
  );

CREATE POLICY "Staff gestiona incidentes"
  ON public.incidentes FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor', 'profesor_admin')
    )
  );

CREATE POLICY "Padres marcan leido incidente"
  ON public.incidentes FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.alumnos a
      WHERE a.id = incidentes.alumno_id
        AND a.padre_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.alumnos_padres ap
      WHERE ap.alumno_id = incidentes.alumno_id
        AND ap.padre_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.alumnos a
      WHERE a.id = incidentes.alumno_id
        AND a.padre_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.alumnos_padres ap
      WHERE ap.alumno_id = incidentes.alumno_id
        AND ap.padre_id = auth.uid()
    )
  );
