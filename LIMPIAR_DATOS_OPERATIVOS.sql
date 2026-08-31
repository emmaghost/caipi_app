-- =====================================================================
-- LIMPIAR DATOS OPERATIVOS — dejar solo catálogos y a Viri (directora)
--
-- QUÉ SE BORRA:
--   ✗ Alumnos y todo lo relacionado (pagos, bitácoras, incidentes,
--     calificaciones, salidas, personas autorizadas, QR, solicitudes,
--     entrevistas, abonos, participantes clases)
--   ✗ Padres (usuarios con rol='padre')
--   ✗ Chat (conversaciones y mensajes)
--   ✗ Notificaciones
--   ✗ Galería
--
-- QUÉ SE CONSERVA:
--   ✓ Directora (Viri)
--   ✓ Profesoras
--   ✓ Grados / grupos
--   ✓ Tipos de incidentes
--   ✓ Configuración de costos
--   ✓ Anuncios y eventos (si quieres borrarlos también descomenta al final)
--   ✓ Menú maternal
--   ✓ Clases extracurriculares (estructura, sin participantes)
--   ✓ Bitácora de gastos
--   ✓ Sistema de permisos (roles, permisos, roles_permisos)
--
-- ORDEN IMPORTANTE: primero hijos, luego padres
--   (foreign keys con ON DELETE CASCADE hacen la mayor parte del trabajo
--    pero es más seguro borrar en orden)
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------
-- 1. Todo lo que depende de alumnos (CASCADE lo haría solo,
--    pero se hace explícito para claridad y por si CASCADE no
--    está en alguna tabla agregada después)
-- ---------------------------------------------------------------
DELETE FROM public.abonos
  WHERE pago_id IN (SELECT id FROM public.pagos);

DELETE FROM public.pagos;

DELETE FROM public.calificaciones;

DELETE FROM public.incidentes;

DELETE FROM public.bitacora_diaria;

DELETE FROM public.control_salidas;

DELETE FROM public.personas_autorizadas;

DELETE FROM public.qr_temporales;

DELETE FROM public.solicitudes_recogida;

DELETE FROM public.entrevistas_padres;

DELETE FROM public.participantes_clases
  WHERE alumno_id IS NOT NULL;   -- conservar externos (alumno_id NULL)

-- ---------------------------------------------------------------
-- 2. Alumnos
-- ---------------------------------------------------------------
DELETE FROM public.alumnos;

-- ---------------------------------------------------------------
-- 3. Padres (usuarios con rol='padre')
--    ON DELETE CASCADE en alumnos.padre_id ya los desvinculó,
--    ahora borramos el usuario de auth también
-- ---------------------------------------------------------------

-- 3a. Borrar de auth.users (la cuenta de acceso)
DELETE FROM auth.users
  WHERE id IN (
    SELECT id FROM public.usuarios WHERE rol = 'padre'
  );

-- 3b. Borrar perfil (debería haberse ido por CASCADE, pero por si acaso)
DELETE FROM public.usuarios WHERE rol = 'padre';

-- ---------------------------------------------------------------
-- 4. Chat: mensajes y conversaciones de padres
-- ---------------------------------------------------------------
DELETE FROM public.mensajes_chat;
DELETE FROM public.conversaciones;

-- ---------------------------------------------------------------
-- 5. Notificaciones
-- ---------------------------------------------------------------
DELETE FROM public.notificaciones;

-- ---------------------------------------------------------------
-- 6. Galería
-- ---------------------------------------------------------------
DELETE FROM public.galeria;

-- ---------------------------------------------------------------
-- Opcional: borrar anuncios y eventos viejos
-- Descomenta si también quieres dejar eso limpio
-- ---------------------------------------------------------------
-- DELETE FROM public.anuncios;
-- DELETE FROM public.eventos;
-- DELETE FROM public.menu_maternal;

-- ---------------------------------------------------------------
-- VERIFICACIÓN — revisa estos números antes de hacer COMMIT
-- ---------------------------------------------------------------
SELECT 'alumnos'             AS tabla, COUNT(*) AS quedan FROM public.alumnos
UNION ALL
SELECT 'pagos',                         COUNT(*) FROM public.pagos
UNION ALL
SELECT 'padres (usuarios)',             COUNT(*) FROM public.usuarios WHERE rol = 'padre'
UNION ALL
SELECT 'directora',                     COUNT(*) FROM public.usuarios WHERE rol = 'directora'
UNION ALL
SELECT 'profesoras',                    COUNT(*) FROM public.usuarios WHERE rol IN ('profesor','profesor_admin')
UNION ALL
SELECT 'grados',                        COUNT(*) FROM public.grados
UNION ALL
SELECT 'tipos_incidentes',              COUNT(*) FROM public.tipos_incidentes
UNION ALL
SELECT 'configuracion_costos',          COUNT(*) FROM public.configuracion_costos
UNION ALL
SELECT 'bitacora_gastos',               COUNT(*) FROM public.bitacora_gastos
UNION ALL
SELECT 'conversaciones',                COUNT(*) FROM public.conversaciones
UNION ALL
SELECT 'solicitudes_recogida',          COUNT(*) FROM public.solicitudes_recogida;

-- Si los números se ven bien → COMMIT
-- Si algo está mal      → ROLLBACK

COMMIT;
-- ROLLBACK;   ← descomenta esta línea y comenta COMMIT si algo está mal
