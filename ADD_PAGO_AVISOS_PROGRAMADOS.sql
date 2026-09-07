-- =============================================================================
-- Avisos de pago programados (directora / caja)
-- Tipos:
--   pronto_pago  = recordatorio pago por llegar (evitar recargo)
--   adeudo       = saldo vencido (pasar a pagar)
--   admin        = mensaje institucional de Administracion CAIPI
-- Ejecutar en Supabase → SQL Editor (completo, se puede re-ejecutar)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.pago_avisos_programados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL DEFAULT 'Aviso de pago',
  dia_mes INT NOT NULL CHECK (dia_mes BETWEEN 1 AND 28),
  titulo TEXT NOT NULL DEFAULT 'Recordatorio de pago',
  mensaje TEXT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT true,
  solo_con_adeudo BOOLEAN NOT NULL DEFAULT true,
  enviar_chat BOOLEAN NOT NULL DEFAULT true,
  enviar_push BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES public.usuarios(id) ON DELETE SET NULL,
  last_run_ymd DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tipo de aviso (migraciones idempotentes)
ALTER TABLE public.pago_avisos_programados
  ADD COLUMN IF NOT EXISTS tipo TEXT NOT NULL DEFAULT 'pronto_pago';

ALTER TABLE public.pago_avisos_programados
  DROP CONSTRAINT IF EXISTS pago_avisos_tipo_chk;

ALTER TABLE public.pago_avisos_programados
  ADD CONSTRAINT pago_avisos_tipo_chk
  CHECK (tipo IN ('pronto_pago', 'adeudo', 'admin'));

CREATE INDEX IF NOT EXISTS idx_pago_avisos_dia
  ON public.pago_avisos_programados(dia_mes) WHERE activo = true;

COMMENT ON TABLE public.pago_avisos_programados IS
  'Plantillas por dia del mes. tipo=pronto_pago|adeudo|admin. Placeholders: {nombre_hijo} {nombres_hijos} {saldo}';
COMMENT ON COLUMN public.pago_avisos_programados.tipo IS
  'pronto_pago | adeudo | admin (mensaje de Administracion CAIPI)';
COMMENT ON COLUMN public.pago_avisos_programados.mensaje IS
  'Texto firmado por Administracion. Usa {nombre_hijo}, {nombres_hijos}, {saldo}';

ALTER TABLE public.pago_avisos_programados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pago_avisos_staff" ON public.pago_avisos_programados;
CREATE POLICY "pago_avisos_staff" ON public.pago_avisos_programados
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'caja')
        AND u.activo = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.rol IN ('directora', 'caja')
        AND u.activo = TRUE
    )
  );

-- ¿El grado es Kínder 1–3?
CREATE OR REPLACE FUNCTION public.grado_es_kinder_colegiatura(p_nombre TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_nombre IS NULL THEN FALSE
    WHEN lower(replace(p_nombre, 'í', 'i')) NOT LIKE '%kinder%' THEN FALSE
    WHEN lower(replace(p_nombre, 'í', 'i')) ~ 'kinder[[:space:]]*4' THEN FALSE
    WHEN lower(replace(p_nombre, 'í', 'i')) ~ 'kinder[[:space:]]*[5-9]' THEN FALSE
    ELSE TRUE
  END;
$$;

-- Padres que aún no liquidaron colegiatura (cualquier saldo pendiente del ciclo)
CREATE OR REPLACE FUNCTION public.padres_con_adeudo_colegiatura()
RETURNS TABLE (
  padre_id UUID,
  alumno_id UUID,
  alumno_nombre TEXT,
  saldo NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    COALESCE(ap.padre_id, a.padre_id) AS padre_id,
    a.id AS alumno_id,
    trim(both FROM coalesce(a.nombre, '') || ' ' || coalesce(a.apellidos, '')) AS alumno_nombre,
    SUM(GREATEST(p.monto - coalesce(p.monto_pagado, 0), 0)) AS saldo
  FROM public.pagos p
  JOIN public.alumnos a ON a.id = p.alumno_id AND a.activo = TRUE
  JOIN public.grados g ON g.id = a.grado_id
  LEFT JOIN public.alumnos_padres ap ON ap.alumno_id = a.id
  WHERE public.grado_es_kinder_colegiatura(g.nombre)
    AND COALESCE(p.tipo_pago, 'mensualidad') IN ('mensualidad', 'otro')
    AND (
      lower(coalesce(p.concepto, '')) LIKE '%colegiatura%'
      OR coalesce(p.tipo_pago, '') = 'mensualidad'
    )
    AND p.estatus IN ('pendiente', 'parcial', 'vencido')
    AND GREATEST(p.monto - coalesce(p.monto_pagado, 0), 0) > 0
    AND COALESCE(ap.padre_id, a.padre_id) IS NOT NULL
  GROUP BY 1, 2, 3
  HAVING SUM(GREATEST(p.monto - coalesce(p.monto_pagado, 0), 0)) > 0;
$$;

-- Solo saldo vencido (fecha límite ya pasó o estatus vencido) — para aviso de adeudo/recargo
CREATE OR REPLACE FUNCTION public.padres_con_adeudo_vencido_colegiatura()
RETURNS TABLE (
  padre_id UUID,
  alumno_id UUID,
  alumno_nombre TEXT,
  saldo NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    COALESCE(ap.padre_id, a.padre_id) AS padre_id,
    a.id AS alumno_id,
    trim(both from coalesce(a.nombre, '') || ' ' || coalesce(a.apellidos, '')) AS alumno_nombre,
    SUM(GREATEST(p.monto - coalesce(p.monto_pagado, 0), 0)) AS saldo
  FROM public.pagos p
  JOIN public.alumnos a ON a.id = p.alumno_id AND a.activo = TRUE
  JOIN public.grados g ON g.id = a.grado_id
  LEFT JOIN public.alumnos_padres ap ON ap.alumno_id = a.id
  WHERE public.grado_es_kinder_colegiatura(g.nombre)
    AND COALESCE(p.tipo_pago, 'mensualidad') IN ('mensualidad', 'otro')
    AND (
      lower(coalesce(p.concepto, '')) LIKE '%colegiatura%'
      OR coalesce(p.tipo_pago, '') = 'mensualidad'
    )
    AND p.estatus IN ('pendiente', 'parcial', 'vencido')
    AND GREATEST(p.monto - coalesce(p.monto_pagado, 0), 0) > 0
    AND (
      p.estatus = 'vencido'
      OR (p.fecha_vencimiento IS NOT NULL AND p.fecha_vencimiento < CURRENT_DATE)
    )
    AND COALESCE(ap.padre_id, a.padre_id) IS NOT NULL
  GROUP BY 1, 2, 3
  HAVING SUM(GREATEST(p.monto - coalesce(p.monto_pagado, 0), 0)) > 0;
$$;

GRANT EXECUTE ON FUNCTION public.padres_con_adeudo_colegiatura() TO authenticated;
GRANT EXECUTE ON FUNCTION public.padres_con_adeudo_vencido_colegiatura() TO authenticated;
GRANT EXECUTE ON FUNCTION public.grado_es_kinder_colegiatura(TEXT) TO authenticated;

CREATE TABLE IF NOT EXISTS public.pago_avisos_envios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aviso_id UUID NOT NULL REFERENCES public.pago_avisos_programados(id) ON DELETE CASCADE,
  padre_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  ymd DATE NOT NULL DEFAULT CURRENT_DATE,
  canal TEXT NOT NULL DEFAULT 'chat',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (aviso_id, padre_id, ymd, canal)
);

ALTER TABLE public.pago_avisos_envios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pago_avisos_envios_staff" ON public.pago_avisos_envios;
CREATE POLICY "pago_avisos_envios_staff" ON public.pago_avisos_envios
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.rol IN ('directora', 'caja') AND u.activo
    )
  );

-- Plantillas iniciales (solo si la tabla está vacía)
INSERT INTO public.pago_avisos_programados
  (nombre, dia_mes, titulo, mensaje, activo, tipo, solo_con_adeudo)
SELECT * FROM (VALUES
  (
    'Pronto pago (evitar recargo)',
    5,
    'Administración CAIPI · Pronto pago',
    E'Mensaje de la Administración CAIPI.\n\nTe recordamos que el pago de colegiatura de {nombres_hijos} está por vencer. Saldo pendiente: {saldo}. Realízalo a tiempo para evitar recargos. Si ya liquidaste el ciclo completo, omite este aviso.\n\n— Administración CAIPI',
    true,
    'pronto_pago',
    true
  ),
  (
    'Adeudo / pasar a pagar',
    11,
    'Administración CAIPI · Tu cuenta tiene adeudo',
    E'Mensaje de la Administración CAIPI.\n\nLa cuenta de {nombres_hijos} tiene adeudo. Saldo actual: {saldo}. Te pedimos pasar a pagar lo antes posible; puede aplicar recargo. Si ya estás al corriente, ignora este mensaje.\n\n— Administración CAIPI',
    true,
    'adeudo',
    true
  ),
  (
    'Aviso Administración',
    1,
    'Administración CAIPI · Aviso de colegiatura',
    E'Mensaje de la Administración CAIPI.\n\nHola. Te escribimos desde la administración escolar respecto a la colegiatura de {nombres_hijos}. Saldo pendiente: {saldo}. Mantente al corriente para evitar recargos y contratiempos. Cualquier duda, responde por este chat.\n\n— Administración CAIPI',
    true,
    'admin',
    true
  )
) AS v(nombre, dia_mes, titulo, mensaje, activo, tipo, solo_con_adeudo)
WHERE NOT EXISTS (SELECT 1 FROM public.pago_avisos_programados LIMIT 1);

-- Si ya habia avisos pero falta el de Administracion, lo agrega
INSERT INTO public.pago_avisos_programados
  (nombre, dia_mes, titulo, mensaje, activo, tipo, solo_con_adeudo)
SELECT
  'Aviso Administracion',
  1,
  'Administracion CAIPI · Aviso de colegiatura',
  E'Mensaje de la Administracion CAIPI.\n\nHola. Te escribimos desde la administracion escolar respecto a la colegiatura de {nombres_hijos}. Saldo pendiente: {saldo}. Mantente al corriente para evitar recargos y contratiempos. Cualquier duda, responde por este chat.\n\n— Administracion CAIPI',
  true,
  'admin',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.pago_avisos_programados WHERE tipo = 'admin'
);

-- Clasificar plantillas existentes (no pisa admin)
UPDATE public.pago_avisos_programados
SET tipo = 'adeudo'
WHERE tipo IS DISTINCT FROM 'admin'
  AND (
    nombre ILIKE '%recargo%'
    OR nombre ILIKE '%adeudo%'
    OR titulo ILIKE '%adeudo%'
    OR titulo ILIKE '%recargo%'
    OR dia_mes >= 11
  );

UPDATE public.pago_avisos_programados
SET tipo = 'pronto_pago'
WHERE tipo IS DISTINCT FROM 'adeudo'
  AND tipo IS DISTINCT FROM 'admin';

NOTIFY pgrst, 'reload schema';
