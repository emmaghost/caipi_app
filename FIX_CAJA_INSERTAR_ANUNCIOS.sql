-- =============================================================================
-- Anuncios: permitir rol caja (y secretaria) insertar avisos de pago
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================

DROP POLICY IF EXISTS "Staff inserta anuncios" ON public.anuncios;

CREATE POLICY "Staff inserta anuncios"
  ON public.anuncios
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN (
          'directora',
          'profesor_admin',
          'profesor',
          'caja',
          'secretaria'
        )
    )
  );

NOTIFY pgrst, 'reload schema';
