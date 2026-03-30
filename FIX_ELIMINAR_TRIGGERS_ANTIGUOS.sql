-- ============================================
-- ELIMINAR TRIGGERS Y FUNCIONES ANTIGUOS
-- ============================================
-- Este script elimina todos los triggers antiguos
-- de pagos para evitar conflictos
-- ============================================

-- 1. Eliminar todos los triggers relacionados con pagos en alumnos
DROP TRIGGER IF EXISTS trigger_crear_pagos_automaticos ON alumnos;
DROP TRIGGER IF EXISTS trigger_crear_pagos ON alumnos;
DROP TRIGGER IF EXISTS crear_pagos_trigger ON alumnos;

-- 2. Eliminar funciones antiguas de creación de pagos
DROP FUNCTION IF EXISTS crear_pagos_automaticos() CASCADE;
DROP FUNCTION IF EXISTS crear_pagos() CASCADE;
DROP FUNCTION IF EXISTS generar_pagos_alumno() CASCADE;

-- ============================================
-- ✅ LISTO
-- ============================================

/*
Este script elimina:
1. ✅ Todos los triggers de creación automática de pagos
2. ✅ Todas las funciones relacionadas

Después de ejecutar esto, ejecuta de nuevo:
- FIX_SISTEMA_BECAS.sql (para recrear el trigger correcto)
*/
