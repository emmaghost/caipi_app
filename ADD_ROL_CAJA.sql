-- =============================================================================
-- Rol CAJA: solo pagos / administración de cobros (sin ver alumnos)
-- =============================================================================

-- Ampliar check de rol en usuarios (si existe)
DO $$
DECLARE
  cname text;
BEGIN
  SELECT conname INTO cname
  FROM pg_constraint
  WHERE conrelid = 'public.usuarios'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) ILIKE '%rol%'
  LIMIT 1;

  IF cname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.usuarios DROP CONSTRAINT %I', cname);
  END IF;

  ALTER TABLE public.usuarios
    ADD CONSTRAINT usuarios_rol_check
    CHECK (rol IN (
      'directora', 'profesor', 'profesor_admin', 'padre', 'secretaria', 'caja'
    ));
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

INSERT INTO public.roles (codigo, nombre, descripcion, nivel)
VALUES (
  'caja',
  'Caja / Pagos',
  'Solo administración de pagos; no ve alumnos ni bitácora',
  4
)
ON CONFLICT (codigo) DO UPDATE
  SET nombre = EXCLUDED.nombre, descripcion = EXCLUDED.descripcion;

-- Permisos de pagos (si existen en permisos)
INSERT INTO public.roles_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permisos p
WHERE r.codigo = 'caja'
  AND p.clave IN (
    'ver_pagos', 'crear_pago', 'editar_pago', 'acreditar_pago', 'eliminar_pago'
  )
ON CONFLICT DO NOTHING;

-- Helper: ¿usuario es caja o directora para pagos?
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

COMMENT ON FUNCTION public.usuario_gestiona_pagos IS
  'Directora o rol caja pueden administrar pagos';
