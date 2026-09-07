-- ============================================================
-- Anuncios: permitir a maestras (rol profesor) publicar / editar / borrar
-- Ejecutar en Supabase → SQL Editor → Run
-- ============================================================

ALTER TABLE public.anuncios ENABLE ROW LEVEL SECURITY;

-- Quitar políticas viejas (nombres históricos)
DROP POLICY IF EXISTS "Ver anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Todos pueden ver anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Gestionar anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Directora gestiona anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Directora puede insertar anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Directora puede actualizar anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Staff inserta anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Staff actualiza anuncios" ON public.anuncios;
DROP POLICY IF EXISTS "Staff elimina anuncios" ON public.anuncios;

-- Lectura: cualquier usuario autenticado (padres ven anuncios de la escuela)
CREATE POLICY "Ver anuncios"
  ON public.anuncios
  FOR SELECT
  TO authenticated
  USING (true);

-- Insertar: directora, supervisora o maestra
CREATE POLICY "Staff inserta anuncios"
  ON public.anuncios
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND u.rol IN ('directora', 'profesor_admin', 'profesor')
    )
  );

-- Actualizar: directora/admin cualquier anuncio; maestra solo los suyos
CREATE POLICY "Staff actualiza anuncios"
  ON public.anuncios
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND (
          u.rol IN ('directora', 'profesor_admin')
          OR (u.rol = 'profesor' AND anuncios.creado_por = auth.uid())
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND (
          u.rol IN ('directora', 'profesor_admin')
          OR (u.rol = 'profesor' AND anuncios.creado_por = auth.uid())
        )
    )
  );

-- Eliminar: misma regla
CREATE POLICY "Staff elimina anuncios"
  ON public.anuncios
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.activo = true
        AND (
          u.rol IN ('directora', 'profesor_admin')
          OR (u.rol = 'profesor' AND anuncios.creado_por = auth.uid())
        )
    )
  );
