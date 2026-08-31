-- =============================================================================
-- Dos papás / mamás por el mismo alumno
-- Ejecutar en Supabase → SQL Editor (NO borra alumnos ni usuarios)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.caipi_es_directora_o_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid()
      AND rol IN ('directora', 'profesor_admin')
  );
$$;

CREATE TABLE IF NOT EXISTS public.alumnos_padres (
  alumno_id UUID NOT NULL REFERENCES public.alumnos(id) ON DELETE CASCADE,
  padre_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  es_principal BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (alumno_id, padre_id)
);

CREATE INDEX IF NOT EXISTS idx_alumnos_padres_padre
  ON public.alumnos_padres(padre_id);

COMMENT ON TABLE public.alumnos_padres IS
  'Vínculo N:N. Un alumno puede tener hasta 2 cuentas de padre/madre.';

GRANT ALL ON TABLE public.alumnos_padres TO authenticated;
GRANT ALL ON TABLE public.alumnos_padres TO service_role;

-- Copiar el padre actual (padre_id) sin duplicar
INSERT INTO public.alumnos_padres (alumno_id, padre_id, es_principal)
SELECT a.id, a.padre_id, true
FROM public.alumnos a
WHERE a.padre_id IS NOT NULL
ON CONFLICT (alumno_id, padre_id) DO NOTHING;

-- Máximo 2 tutores por niño
CREATE OR REPLACE FUNCTION public.caipi_limite_dos_padres()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Upsert del mismo tutor no cuenta como un tercero.
  IF EXISTS (
    SELECT 1 FROM public.alumnos_padres
    WHERE alumno_id = NEW.alumno_id AND padre_id = NEW.padre_id
  ) THEN
    RETURN NEW;
  END IF;
  IF (
    SELECT COUNT(*) FROM public.alumnos_padres
    WHERE alumno_id = NEW.alumno_id
  ) >= 2 THEN
    RAISE EXCEPTION 'Este alumno ya tiene 2 padres vinculados';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_limite_dos_padres ON public.alumnos_padres;
CREATE TRIGGER trg_limite_dos_padres
  BEFORE INSERT ON public.alumnos_padres
  FOR EACH ROW
  EXECUTE FUNCTION public.caipi_limite_dos_padres();

-- ¿El usuario logueado es tutor de este alumno?
CREATE OR REPLACE FUNCTION public.caipi_es_padre_de_alumno(p_alumno_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    auth.uid() IS NOT NULL
    AND (
      EXISTS (
        SELECT 1 FROM public.alumnos_padres ap
        WHERE ap.alumno_id = p_alumno_id
          AND ap.padre_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.alumnos a
        WHERE a.id = p_alumno_id
          AND a.padre_id = auth.uid()
      )
    );
$$;

GRANT EXECUTE ON FUNCTION public.caipi_es_padre_de_alumno(uuid) TO authenticated;

-- Si cambian alumnos.padre_id, mantenerlo en la tabla de vínculo
CREATE OR REPLACE FUNCTION public.caipi_sync_padre_principal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.padre_id IS NOT NULL THEN
    INSERT INTO public.alumnos_padres (alumno_id, padre_id, es_principal)
    VALUES (NEW.id, NEW.padre_id, true)
    ON CONFLICT (alumno_id, padre_id) DO UPDATE
      SET es_principal = true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_padre_principal ON public.alumnos;
CREATE TRIGGER trg_sync_padre_principal
  AFTER INSERT OR UPDATE OF padre_id ON public.alumnos
  FOR EACH ROW
  EXECUTE FUNCTION public.caipi_sync_padre_principal();

-- ---------------------------------------------------------------------------
-- RLS de alumnos_padres
-- ---------------------------------------------------------------------------
ALTER TABLE public.alumnos_padres ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "alumnos_padres_select" ON public.alumnos_padres;
CREATE POLICY "alumnos_padres_select" ON public.alumnos_padres
  FOR SELECT TO authenticated
  USING (
    padre_id = auth.uid()
    OR public.caipi_es_directora_o_admin()
    OR EXISTS (
      SELECT 1 FROM public.profesores p
      WHERE p.usuario_id = auth.uid() AND p.activo = true
    )
  );

DROP POLICY IF EXISTS "alumnos_padres_write" ON public.alumnos_padres;
CREATE POLICY "alumnos_padres_write" ON public.alumnos_padres
  FOR ALL TO authenticated
  USING (public.caipi_es_directora_o_admin())
  WITH CHECK (public.caipi_es_directora_o_admin());

-- ---------------------------------------------------------------------------
-- Alumno: el 2.º papá también lo ve
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "alumnos_select" ON public.alumnos;
CREATE POLICY "alumnos_select" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(id)
    OR public.caipi_es_directora_o_admin()
    OR EXISTS (
      SELECT 1 FROM public.profesores p
      WHERE p.usuario_id = auth.uid()
        AND p.grado_id = alumnos.grado_id
        AND p.activo = true
    )
  );

DROP POLICY IF EXISTS "Ver alumnos" ON public.alumnos;
CREATE POLICY "Ver alumnos" ON public.alumnos
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid()
        AND rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

-- ---------------------------------------------------------------------------
-- Pagos / abonos
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Ver pagos" ON public.pagos;
CREATE POLICY "Ver pagos" ON public.pagos
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

DROP POLICY IF EXISTS "Padres ven abonos de sus hijos" ON public.abonos;
CREATE POLICY "Padres ven abonos de sus hijos"
  ON public.abonos FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.pagos p
      WHERE p.id = abonos.pago_id
        AND public.caipi_es_padre_de_alumno(p.alumno_id)
    )
  );

-- ---------------------------------------------------------------------------
-- Bitácora, salidas, personas autorizadas, incidentes
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Ver bitacora" ON public.bitacora_diaria;
CREATE POLICY "Ver bitacora" ON public.bitacora_diaria
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

DROP POLICY IF EXISTS "Ver salidas" ON public.control_salidas;
CREATE POLICY "Ver salidas" ON public.control_salidas
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

DROP POLICY IF EXISTS "Ver personas autorizadas" ON public.personas_autorizadas;
CREATE POLICY "Ver personas autorizadas" ON public.personas_autorizadas
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

DROP POLICY IF EXISTS "Gestionar personas autorizadas" ON public.personas_autorizadas;
CREATE POLICY "Gestionar personas autorizadas" ON public.personas_autorizadas
  FOR ALL TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin')
    )
  )
  WITH CHECK (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.rol IN ('directora', 'profesor_admin')
    )
  );

DROP POLICY IF EXISTS "Ver incidentes" ON public.incidentes;
DROP POLICY IF EXISTS "Padres ven incidentes de sus hijos" ON public.incidentes;
CREATE POLICY "Ver incidentes" ON public.incidentes
  FOR SELECT TO authenticated
  USING (
    public.caipi_es_padre_de_alumno(alumno_id)
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

-- ---------------------------------------------------------------------------
-- Tablas opcionales (si no existen, se ignora)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.qr_temporales') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "Padres ven sus QR temporales" ON public.qr_temporales';
    EXECUTE $p$CREATE POLICY "Padres ven sus QR temporales" ON public.qr_temporales
      FOR SELECT TO authenticated
      USING (public.caipi_es_padre_de_alumno(alumno_id))$p$;
    EXECUTE 'DROP POLICY IF EXISTS "Padres crean QR temporales" ON public.qr_temporales';
    EXECUTE $p$CREATE POLICY "Padres crean QR temporales" ON public.qr_temporales
      FOR INSERT TO authenticated
      WITH CHECK (public.caipi_es_padre_de_alumno(alumno_id))$p$;
  END IF;

  IF to_regclass('public.solicitudes_recogida') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "Padre ve sus solicitudes" ON public.solicitudes_recogida';
    EXECUTE $p$CREATE POLICY "Padre ve sus solicitudes"
      ON public.solicitudes_recogida FOR SELECT TO authenticated
      USING (padre_id = auth.uid() OR public.caipi_es_padre_de_alumno(alumno_id))$p$;
    EXECUTE 'DROP POLICY IF EXISTS "Padre crea solicitud" ON public.solicitudes_recogida';
    EXECUTE $p$CREATE POLICY "Padre crea solicitud"
      ON public.solicitudes_recogida FOR INSERT TO authenticated
      WITH CHECK (padre_id = auth.uid() AND public.caipi_es_padre_de_alumno(alumno_id))$p$;
  END IF;

  IF to_regclass('public.portage_resultados') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "portage_resultados_padre_lectura" ON public.portage_resultados';
    EXECUTE $p$CREATE POLICY "portage_resultados_padre_lectura" ON public.portage_resultados
      FOR SELECT USING (
        public.caipi_es_padre_de_alumno(alumno_id)
        AND EXISTS (
          SELECT 1 FROM public.alumnos a
          WHERE a.id = portage_resultados.alumno_id
            AND a.portage_visible_padre = true
        )
      )$p$;
  END IF;

  IF to_regclass('public.ligas_drive') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "ligas_drive_padre_lectura" ON public.ligas_drive';
    EXECUTE $p$CREATE POLICY "ligas_drive_padre_lectura" ON public.ligas_drive
      FOR SELECT USING (
        activa = true
        AND (
          alcance = 'general'
          OR EXISTS (
            SELECT 1
            FROM public.ligas_drive_grados ldg
            JOIN public.alumnos a ON a.grado_id = ldg.grado_id
            WHERE ldg.liga_id = ligas_drive.id
              AND public.caipi_es_padre_de_alumno(a.id)
          )
        )
      )$p$;
  END IF;

  IF to_regclass('public.ligas_drive_grados') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "ligas_drive_grados_padre_lectura" ON public.ligas_drive_grados';
    EXECUTE $p$CREATE POLICY "ligas_drive_grados_padre_lectura" ON public.ligas_drive_grados
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.alumnos a
          WHERE a.grado_id = ligas_drive_grados.grado_id
            AND public.caipi_es_padre_de_alumno(a.id)
        )
      )$p$;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
