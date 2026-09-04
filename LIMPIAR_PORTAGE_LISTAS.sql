-- =============================================================================
-- LIMPIAR Portage (listas + indicadores + evaluaciones + calificaciones)
-- Úsalo SI quieres empezar limpio antes de ADD_PORTAGE_TIPO_Y_PLANTILLA.sql
--
-- ⚠️ Borra TODO lo de desarrollo/alertas ya calificado.
-- No toca alumnos, pagos, chat ni usuarios.
-- =============================================================================

-- Orden por si no hubiera CASCADE en algún entorno viejo
DELETE FROM public.portage_resultados;
DELETE FROM public.portage_evaluaciones;
DELETE FROM public.portage_indicadores;
DELETE FROM public.portage_listas;

-- Verificación (debe dar 0 en todo)
SELECT
  (SELECT count(*) FROM public.portage_listas) AS listas,
  (SELECT count(*) FROM public.portage_indicadores) AS indicadores,
  (SELECT count(*) FROM public.portage_evaluaciones) AS evaluaciones,
  (SELECT count(*) FROM public.portage_resultados) AS calificaciones;
