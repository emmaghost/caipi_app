-- ============================================================
-- 1) RLS: caja (y directora) pueden gestionar pagos y abonos
-- 2) Marcar TODOS los pagos de Agosto 2026 como pagados
-- Ejecutar en Supabase → SQL Editor → Run
-- ============================================================

-- ---------- RLS pagos / abonos ----------
CREATE OR REPLACE FUNCTION public.usuario_gestiona_pagos(p_uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = p_uid
      AND u.rol IN ('directora', 'caja')
      AND u.activo = TRUE
  );
$$;

DROP POLICY IF EXISTS "Directora gestiona pagos" ON public.pagos;
DROP POLICY IF EXISTS "Staff gestiona pagos" ON public.pagos;
CREATE POLICY "Staff gestiona pagos"
  ON public.pagos FOR ALL TO authenticated
  USING (public.usuario_gestiona_pagos())
  WITH CHECK (public.usuario_gestiona_pagos());

DROP POLICY IF EXISTS "Directora gestiona abonos" ON public.abonos;
DROP POLICY IF EXISTS "Staff gestiona abonos" ON public.abonos;
CREATE POLICY "Staff gestiona abonos"
  ON public.abonos FOR ALL TO authenticated
  USING (public.usuario_gestiona_pagos())
  WITH CHECK (public.usuario_gestiona_pagos());

-- ---------- Vista previa (opcional): cuántos se van a marcar ----------
-- SELECT id, mes, concepto, monto, monto_pagado, estatus, fecha_vencimiento
-- FROM public.pagos
-- WHERE estatus IS DISTINCT FROM 'pagado'
--   AND (
--     mes ILIKE 'Agosto%2026%'
--     OR mes ILIKE 'Agosto 2026'
--     OR mes = 'Agosto'
--     OR (
--       fecha_vencimiento >= '2026-08-01'
--       AND fecha_vencimiento < '2026-09-01'
--     )
--   );

-- ---------- Marcar Agosto 2026 como pagados ----------
UPDATE public.pagos
SET
  monto_pagado = monto,
  estatus = 'pagado',
  fecha_pago = COALESCE(fecha_pago, DATE '2026-08-31'),
  forma_pago = COALESCE(forma_pago, 'Efectivo'),
  notas = CASE
    WHEN notas IS NULL OR btrim(notas) = '' THEN 'Marcado pagado (ajuste masivo Agosto 2026)'
    WHEN notas ILIKE '%ajuste masivo Agosto 2026%' THEN notas
    ELSE notas || ' | Marcado pagado (ajuste masivo Agosto 2026)'
  END,
  updated_at = NOW()
WHERE COALESCE(estatus, '') IS DISTINCT FROM 'pagado'
  AND (
    mes ILIKE 'Agosto%2026%'
    OR (
      fecha_vencimiento >= DATE '2026-08-01'
      AND fecha_vencimiento < DATE '2026-09-01'
    )
  );

-- Verificación
SELECT
  COUNT(*) FILTER (WHERE estatus = 'pagado') AS pagados_agosto,
  COUNT(*) FILTER (WHERE estatus IS DISTINCT FROM 'pagado') AS pendientes_agosto
FROM public.pagos
WHERE
  mes ILIKE 'Agosto%2026%'
  OR (
    fecha_vencimiento >= DATE '2026-08-01'
    AND fecha_vencimiento < DATE '2026-09-01'
  );
