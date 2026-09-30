-- =============================================================================
-- Aviso obligatorio de actualización (Play Store / App Store)
-- Ejecutar en Supabase → SQL Editor → Run
--
-- La app compara su número de build (el +4018 de 1.0.15+4018) con build_minimo.
-- El mismo número vale para iPhone y Android: los dos salen de pubspec.yaml.
-- Si la app es más vieja y activo = true, no deja entrar y abre su tienda.
--
-- 1.0.14 y anteriores NO traen este chequeo: no se van a bloquear.
-- Primero publica 1.0.15 (build 4018) en Play Store y en App Store.
--
-- Para PROBAR la pantalla (en un celular que ya tenga 1.0.15):
--   UPDATE public.app_actualizacion
--   SET activo = true, build_minimo = 4019
--   WHERE id = 1;
-- La app 4018 queda bloqueada y el botón abre la tienda.
-- Para volver a entrar:
--   UPDATE public.app_actualizacion SET activo = false WHERE id = 1;
--
-- Para obligar a actualizar MÁS ADELANTE: cuando el build nuevo ya esté
-- en las DOS tiendas, pon build_minimo = ese build (y activo = true).
-- No lo enciendas si iOS todavía no tiene esa versión.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.app_actualizacion (
  id smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  activo boolean NOT NULL DEFAULT false,
  build_minimo integer NOT NULL DEFAULT 0,
  mensaje text NOT NULL DEFAULT
    'Hay una versión nueva de CAIPI. Actualiza desde la tienda para seguir usando la app.',
  url_android text NOT NULL DEFAULT
    'https://play.google.com/store/apps/details?id=com.escuela.caipi',
  url_ios text NOT NULL DEFAULT
    'https://apps.apple.com/search?term=CAIPI'
);

INSERT INTO public.app_actualizacion (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_actualizacion ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_actualizacion_lectura" ON public.app_actualizacion;
CREATE POLICY "app_actualizacion_lectura"
  ON public.app_actualizacion
  FOR SELECT
  TO anon, authenticated
  USING (true);

COMMENT ON TABLE public.app_actualizacion IS
  'Una sola fila (id=1). build_minimo = número después del + en pubspec (1.0.14+4017 → 4017).';
