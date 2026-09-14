-- =============================================================================
-- Consulta: qué papá(s) están apegados a qué hijo (hasta 2 tutores)
-- Supabase → SQL Editor → Run → botón Download CSV (ábrelo en Excel)
-- =============================================================================

WITH vinculos AS (
  SELECT
    a.id AS alumno_id,
    a.padre_id AS padre_id,
    true AS es_principal
  FROM public.alumnos a
  WHERE a.padre_id IS NOT NULL

  UNION

  SELECT
    ap.alumno_id,
    ap.padre_id,
    COALESCE(ap.es_principal, false) AS es_principal
  FROM public.alumnos_padres ap
),
conteo AS (
  SELECT alumno_id, COUNT(DISTINCT padre_id) AS n_padres
  FROM vinculos
  GROUP BY alumno_id
)
SELECT
  COALESCE(g.nombre, '(sin grado)') AS grado,
  trim(both ' ' FROM concat_ws(' ', a.nombre, a.apellidos)) AS alumno,
  CASE WHEN COALESCE(a.activo, true) THEN 'Sí' ELSE 'No' END AS alumno_activo,
  COALESCE(c.n_padres, 0) AS cuantos_padres,
  trim(both ' ' FROM concat_ws(' ', u.nombre, u.apellidos)) AS padre,
  u.email AS padre_email,
  COALESCE(u.whatsapp, u.telefono) AS padre_telefono,
  CASE
    WHEN bool_or(v.es_principal) OR a.padre_id = u.id THEN 'Principal'
    ELSE 'Segundo tutor'
  END AS tipo_vinculo
FROM vinculos v
JOIN public.alumnos a ON a.id = v.alumno_id
JOIN public.usuarios u ON u.id = v.padre_id AND u.rol = 'padre'
LEFT JOIN conteo c ON c.alumno_id = a.id
LEFT JOIN public.grados g ON g.id = a.grado_id
GROUP BY
  g.nombre, a.id, a.nombre, a.apellidos, a.activo, a.padre_id,
  c.n_padres,
  u.id, u.nombre, u.apellidos, u.email, u.whatsapp, u.telefono
ORDER BY
  g.nombre NULLS LAST,
  a.apellidos,
  a.nombre,
  tipo_vinculo,
  u.apellidos,
  u.nombre;
