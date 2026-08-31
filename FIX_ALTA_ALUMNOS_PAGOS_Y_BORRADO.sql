-- CAIPI: corrección segura del alta de alumnos y gestión de pagos.
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- No elimina alumnos, usuarios ni pagos existentes.

BEGIN;

-- Unificar la columna de vencimiento usada por Flutter.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'pagos'
      AND column_name = 'fecha_limite'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'pagos'
      AND column_name = 'fecha_vencimiento'
  ) THEN
    ALTER TABLE public.pagos
      RENAME COLUMN fecha_limite TO fecha_vencimiento;
  END IF;
END $$;

ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS fecha_vencimiento DATE,
  ADD COLUMN IF NOT EXISTS monto_pagado NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS estatus TEXT NOT NULL DEFAULT 'pendiente',
  ADD COLUMN IF NOT EXISTS forma_pago TEXT,
  ADD COLUMN IF NOT EXISTS notas TEXT,
  ADD COLUMN IF NOT EXISTS anio_escolar INTEGER,
  ADD COLUMN IF NOT EXISTS tipo_pago TEXT,
  ADD COLUMN IF NOT EXISTS recibido_por_nombre TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Migrar los valores del esquema anterior, si todavía están presentes.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'pagos'
      AND column_name = 'pagado'
  ) THEN
    UPDATE public.pagos
    SET estatus = CASE WHEN pagado THEN 'pagado' ELSE 'pendiente' END
    WHERE estatus IS NULL OR estatus = 'pendiente';
  END IF;
END $$;

ALTER TABLE public.pagos DROP CONSTRAINT IF EXISTS pagos_estatus_check;
ALTER TABLE public.pagos
  ADD CONSTRAINT pagos_estatus_check
  CHECK (estatus IN ('pendiente', 'parcial', 'pagado', 'vencido', 'cancelado'));

CREATE INDEX IF NOT EXISTS idx_pagos_fecha_vencimiento
  ON public.pagos(fecha_vencimiento);

-- Asegurar que Viri/directora pueda leer y administrar grados, alumnos y pagos.
ALTER TABLE public.grados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alumnos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pagos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ver grados" ON public.grados;
CREATE POLICY "Ver grados"
  ON public.grados FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Gestionar grados" ON public.grados;
CREATE POLICY "Gestionar grados"
  ON public.grados FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

DROP POLICY IF EXISTS "Directora gestiona alumnos" ON public.alumnos;
CREATE POLICY "Directora gestiona alumnos"
  ON public.alumnos FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

DROP POLICY IF EXISTS "Directora gestiona pagos" ON public.pagos;
CREATE POLICY "Directora gestiona pagos"
  ON public.pagos FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  );

-- Abonos y folios de recibo.
CREATE TABLE IF NOT EXISTS public.abonos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pago_id UUID NOT NULL REFERENCES public.pagos(id) ON DELETE CASCADE,
  monto NUMERIC(10,2) NOT NULL CHECK (monto > 0),
  fecha_abono DATE NOT NULL DEFAULT CURRENT_DATE,
  forma_pago TEXT,
  referencia TEXT,
  notas TEXT,
  recibido_por_nombre TEXT,
  recibo_folio TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES public.usuarios(id)
);

ALTER TABLE public.abonos
  ADD COLUMN IF NOT EXISTS recibido_por_nombre TEXT;

CREATE INDEX IF NOT EXISTS idx_abonos_pago
  ON public.abonos(pago_id);

CREATE OR REPLACE FUNCTION public.generar_folio_recibo()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_anio TEXT := TO_CHAR(CURRENT_DATE, 'YYYY');
  v_consecutivo INTEGER;
BEGIN
  -- Evita folios repetidos si dos pagos se registran al mismo tiempo.
  PERFORM pg_advisory_xact_lock(hashtext('caipi_folio_recibo_' || v_anio));
  SELECT COALESCE(
    MAX(CAST(SUBSTRING(recibo_folio FROM '\d+$') AS INTEGER)),
    0
  ) + 1
  INTO v_consecutivo
  FROM public.abonos
  WHERE recibo_folio LIKE 'REC-' || v_anio || '-%';

  RETURN 'REC-' || v_anio || '-' || LPAD(v_consecutivo::TEXT, 4, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.preparar_abono()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.recibo_folio IS NULL THEN
    NEW.recibo_folio := public.generar_folio_recibo();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_preparar_abono ON public.abonos;
CREATE TRIGGER trigger_preparar_abono
  BEFORE INSERT ON public.abonos
  FOR EACH ROW EXECUTE FUNCTION public.preparar_abono();

CREATE OR REPLACE FUNCTION public.actualizar_pago_desde_abono()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total NUMERIC(10,2);
  v_monto NUMERIC(10,2);
BEGIN
  SELECT COALESCE(SUM(monto), 0)
  INTO v_total
  FROM public.abonos
  WHERE pago_id = NEW.pago_id;

  SELECT monto INTO v_monto
  FROM public.pagos
  WHERE id = NEW.pago_id
  FOR UPDATE;

  UPDATE public.pagos
  SET monto_pagado = v_total,
      estatus = CASE
        WHEN v_total >= v_monto THEN 'pagado'
        WHEN v_total > 0 THEN 'parcial'
        ELSE 'pendiente'
      END,
      fecha_pago = CASE
        WHEN v_total >= v_monto THEN NEW.fecha_abono
        ELSE NULL
      END,
      forma_pago = NEW.forma_pago,
      referencia = NEW.referencia,
      notas = COALESCE(NEW.notas, notas),
      recibido_por_nombre = NEW.recibido_por_nombre,
      updated_at = NOW()
  WHERE id = NEW.pago_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_actualizar_pago_desde_abono
  ON public.abonos;
CREATE TRIGGER trigger_actualizar_pago_desde_abono
  AFTER INSERT ON public.abonos
  FOR EACH ROW EXECUTE FUNCTION public.actualizar_pago_desde_abono();

ALTER TABLE public.abonos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Directora gestiona abonos" ON public.abonos;
CREATE POLICY "Directora gestiona abonos"
  ON public.abonos FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol IN ('directora', 'profesor_admin')
    )
  )
  WITH CHECK (
    EXISTS (
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
      JOIN public.alumnos a ON a.id = p.alumno_id
      WHERE p.id = abonos.pago_id AND a.padre_id = auth.uid()
    )
  );

-- Actualiza inmediatamente la caché de esquema de PostgREST.
NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verificación: ambas consultas deben devolver filas sin error.
SELECT id, nombre, activo FROM public.grados ORDER BY nombre;
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'pagos'
ORDER BY ordinal_position;
