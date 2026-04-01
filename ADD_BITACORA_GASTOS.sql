-- Bitácora de gastos (compras / egresos narrados por la directora).
-- Ejecutar en Supabase → SQL Editor.
-- Luego: Database → Replication → supabase_realtime → añadir tabla bitacora_gastos (opcional, para stream en vivo).

CREATE TABLE IF NOT EXISTS public.bitacora_gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL DEFAULT (CURRENT_DATE),
  descripcion TEXT NOT NULL,
  monto NUMERIC(12, 2) NOT NULL CHECK (monto >= 0),
  -- NULL = gasto general de toda la escuela; si tiene valor = asociado a un grupo/grado
  grado_id UUID REFERENCES public.grados(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bitacora_gastos_fecha ON public.bitacora_gastos (fecha DESC);
CREATE INDEX IF NOT EXISTS idx_bitacora_gastos_grado ON public.bitacora_gastos (grado_id);

ALTER TABLE public.bitacora_gastos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Directora gestiona bitacora gastos" ON public.bitacora_gastos;

CREATE POLICY "Directora gestiona bitacora gastos"
ON public.bitacora_gastos
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
    AND u.rol IN ('directora', 'profesor_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid()
    AND u.rol IN ('directora', 'profesor_admin')
  )
);

COMMENT ON TABLE public.bitacora_gastos IS 'Registro libre de gastos/compras; grado_id nulo = CAIPI en general';
