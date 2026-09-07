-- =============================================================================
-- Entrega: modalidad (padre | qr) + borrar histórico si hubo error
-- Ejecutar en Supabase → SQL Editor → Run
-- =============================================================================

ALTER TABLE public.solicitudes_recogida
  ADD COLUMN IF NOT EXISTS modalidad_entrega TEXT;

ALTER TABLE public.solicitudes_recogida
  DROP CONSTRAINT IF EXISTS solicitudes_recogida_modalidad_check;

ALTER TABLE public.solicitudes_recogida
  ADD CONSTRAINT solicitudes_recogida_modalidad_check
  CHECK (
    modalidad_entrega IS NULL
    OR modalidad_entrega IN ('padre', 'qr')
  );

ALTER TABLE public.solicitudes_recogida
  ADD COLUMN IF NOT EXISTS quien_recibio TEXT;

COMMENT ON COLUMN public.solicitudes_recogida.modalidad_entrega IS
  'padre = entregado al papá/mamá en puerta; qr = validó código QR';
COMMENT ON COLUMN public.solicitudes_recogida.quien_recibio IS
  'Nombre de quien recogió (papá o persona autorizada del QR)';

-- Escuela puede borrar una solicitud (equivocación → quitar histórico)
DROP POLICY IF EXISTS "Escuela borra solicitud" ON public.solicitudes_recogida;
CREATE POLICY "Escuela borra solicitud"
ON public.solicitudes_recogida FOR DELETE TO authenticated
USING (public.usuario_es_escuela());

NOTIFY pgrst, 'reload schema';
