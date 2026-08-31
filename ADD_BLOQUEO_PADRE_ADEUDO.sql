-- =============================================================================
-- Bloqueo de acceso padre por adeudo de colegiatura
-- Regla: 5 días después de la fecha de vencimiento, si sigue sin pagar.
-- Si un hijo debe → todos sus papás vinculados quedan restringidos.
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================

ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS acceso_app_modo TEXT DEFAULT 'automatico';
ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS acceso_app_nota TEXT;
ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS acceso_app_hasta TIMESTAMPTZ;

COMMENT ON COLUMN public.usuarios.acceso_app_modo IS
  'Padres: automatico | desbloqueado | bloqueado';
COMMENT ON COLUMN public.usuarios.acceso_app_nota IS
  'Nota interna de la directora sobre acceso (convenio, etc.)';
COMMENT ON COLUMN public.usuarios.acceso_app_hasta IS
  'Si desbloqueado: hasta cuándo ignorar adeudo automático';

-- Constante de gracia (días después del vencimiento)
CREATE OR REPLACE FUNCTION public.dias_gracia_bloqueo_padre()
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$ SELECT 5 $$;

-- ¿Este alumno tiene colegiatura que ya amerita bloqueo?
CREATE OR REPLACE FUNCTION public.alumno_genera_bloqueo_adeudo(p_alumno_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.alumno_id = p_alumno_id
      AND lower(coalesce(p.tipo_pago, '')) = 'mensualidad'
      AND coalesce(p.estatus, '') NOT IN ('pagado', 'cancelado')
      AND coalesce(p.monto_pagado, 0) < coalesce(p.monto, 0)
      AND p.fecha_vencimiento IS NOT NULL
      AND CURRENT_DATE > (p.fecha_vencimiento::date + public.dias_gracia_bloqueo_padre())
  );
$$;

-- IDs de alumnos vinculados a un papá (principal + alumnos_padres)
CREATE OR REPLACE FUNCTION public.alumno_ids_de_padre(p_padre_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT a.id
  FROM public.alumnos a
  WHERE a.activo = TRUE
    AND (
      a.padre_id = p_padre_id
      OR EXISTS (
        SELECT 1 FROM public.alumnos_padres ap
        WHERE ap.alumno_id = a.id AND ap.padre_id = p_padre_id
      )
    );
$$;

-- Estado de acceso del papá (JSON para la app)
CREATE OR REPLACE FUNCTION public.padre_acceso_restringido(p_padre_id UUID DEFAULT auth.uid())
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_modo TEXT;
  v_nota TEXT;
  v_hasta TIMESTAMPTZ;
  v_adeudos JSONB := '[]'::jsonb;
  v_row RECORD;
BEGIN
  SELECT
    coalesce(u.acceso_app_modo, 'automatico'),
    u.acceso_app_nota,
    u.acceso_app_hasta
  INTO v_modo, v_nota, v_hasta
  FROM public.usuarios u
  WHERE u.id = p_padre_id AND u.rol = 'padre';

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'restringido', false,
      'modo', 'automatico',
      'motivo', null,
      'nota_directora', null,
      'dias_gracia', public.dias_gracia_bloqueo_padre(),
      'adeudos', '[]'::jsonb
    );
  END IF;

  -- Desbloqueo manual vigente
  IF v_modo = 'desbloqueado'
     AND (v_hasta IS NULL OR v_hasta >= NOW()) THEN
    RETURN jsonb_build_object(
      'restringido', false,
      'modo', 'desbloqueado',
      'motivo', 'Desbloqueado por la escuela',
      'nota_directora', v_nota,
      'dias_gracia', public.dias_gracia_bloqueo_padre(),
      'adeudos', '[]'::jsonb
    );
  END IF;

  -- Bloqueo manual
  IF v_modo = 'bloqueado' THEN
    RETURN jsonb_build_object(
      'restringido', true,
      'modo', 'bloqueado',
      'motivo', coalesce(v_nota, 'Acceso restringido por la escuela'),
      'nota_directora', v_nota,
      'dias_gracia', public.dias_gracia_bloqueo_padre(),
      'adeudos', '[]'::jsonb
    );
  END IF;

  -- Automático: adeudos de hijos vinculados
  FOR v_row IN
    SELECT
      a.id AS alumno_id,
      trim(coalesce(a.nombre, '') || ' ' || coalesce(a.apellidos, '')) AS alumno_nombre,
      p.mes,
      p.monto,
      (p.monto - coalesce(p.monto_pagado, 0)) AS saldo,
      p.fecha_vencimiento
    FROM public.alumno_ids_de_padre(p_padre_id) aid
    JOIN public.alumnos a ON a.id = aid
    JOIN public.pagos p ON p.alumno_id = a.id
    WHERE lower(coalesce(p.tipo_pago, '')) = 'mensualidad'
      AND coalesce(p.estatus, '') NOT IN ('pagado', 'cancelado')
      AND coalesce(p.monto_pagado, 0) < coalesce(p.monto, 0)
      AND p.fecha_vencimiento IS NOT NULL
      AND CURRENT_DATE > (p.fecha_vencimiento::date + public.dias_gracia_bloqueo_padre())
    ORDER BY p.fecha_vencimiento ASC
  LOOP
    v_adeudos := v_adeudos || jsonb_build_array(
      jsonb_build_object(
        'alumno_id', v_row.alumno_id,
        'alumno_nombre', v_row.alumno_nombre,
        'mes', v_row.mes,
        'monto', v_row.monto,
        'saldo', v_row.saldo,
        'fecha_vencimiento', v_row.fecha_vencimiento
      )
    );
  END LOOP;

  IF jsonb_array_length(v_adeudos) > 0 THEN
    RETURN jsonb_build_object(
      'restringido', true,
      'modo', 'automatico',
      'motivo', 'Colegiatura(s) pendiente(s) de pago',
      'nota_directora', v_nota,
      'dias_gracia', public.dias_gracia_bloqueo_padre(),
      'adeudos', v_adeudos
    );
  END IF;

  RETURN jsonb_build_object(
    'restringido', false,
    'modo', coalesce(v_modo, 'automatico'),
    'motivo', null,
    'nota_directora', v_nota,
    'dias_gracia', public.dias_gracia_bloqueo_padre(),
    'adeudos', '[]'::jsonb
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.padre_acceso_restringido(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.alumno_genera_bloqueo_adeudo(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
