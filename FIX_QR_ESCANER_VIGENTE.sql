-- El QR de recogida solo da salida si sigue vigente (activo, sin usar y sin expirar).
-- Si ya se usó, expiró o se apagó, no se consume de nuevo y devuelve a quién avisar.
-- p_alumno_esperado: si viene y el código es de otro niño, no se marca como usado.

CREATE OR REPLACE FUNCTION public.validar_qr_temporal(
  p_codigo TEXT,
  p_usuario_id UUID,
  p_alumno_esperado UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_qr RECORD;
  v_motivo TEXT;
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.usuarios u
    WHERE u.id = auth.uid()
      AND u.rol IN ('directora', 'profesor', 'profesor_admin')
  ) THEN
    RETURN json_build_object(
      'valido', FALSE,
      'motivo', 'sin_permiso',
      'mensaje', 'Sin permiso para validar QR'
    );
  END IF;

  SELECT *
  INTO v_qr
  FROM public.qr_temporales
  WHERE codigo = upper(trim(p_codigo))
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'valido', FALSE,
      'motivo', 'no_existe',
      'mensaje', 'QR inválido, usado o expirado'
    );
  END IF;

  IF COALESCE(v_qr.activo, FALSE) IS NOT TRUE THEN
    v_motivo := 'inactivo';
  ELSIF COALESCE(v_qr.usado, FALSE) IS TRUE THEN
    v_motivo := 'usado';
  ELSIF v_qr.fecha_expiracion <= NOW() THEN
    v_motivo := 'expirado';
  ELSIF p_alumno_esperado IS NOT NULL
        AND v_qr.alumno_id IS DISTINCT FROM p_alumno_esperado THEN
    RETURN json_build_object(
      'valido', FALSE,
      'motivo', 'otro_nino',
      'mensaje', 'QR de otro niño',
      'alumno_id', v_qr.alumno_id,
      'generado_por', v_qr.generado_por
    );
  ELSE
    UPDATE public.qr_temporales
    SET usado = TRUE,
        fecha_uso = NOW(),
        usado_por = auth.uid()
    WHERE id = v_qr.id;

    RETURN json_build_object(
      'valido', TRUE,
      'motivo', 'vigente',
      'mensaje', 'QR válido',
      'alumno_id', v_qr.alumno_id,
      'persona_autorizada_id', v_qr.persona_autorizada_id,
      'generado_por', v_qr.generado_por
    );
  END IF;

  RETURN json_build_object(
    'valido', FALSE,
    'motivo', v_motivo,
    'mensaje', 'QR inválido, usado o expirado',
    'alumno_id', v_qr.alumno_id,
    'generado_por', v_qr.generado_por
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.validar_qr_temporal(
  p_codigo TEXT,
  p_usuario_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.validar_qr_temporal(p_codigo, p_usuario_id, NULL);
END;
$$;

GRANT EXECUTE ON FUNCTION public.validar_qr_temporal(TEXT, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validar_qr_temporal(TEXT, UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
