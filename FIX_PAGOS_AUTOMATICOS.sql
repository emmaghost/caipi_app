-- ============================================
-- TRIGGER: GENERAR PAGOS AUTOMÁTICOS AL CREAR ALUMNO
-- ============================================
-- Este script crea el trigger que genera automáticamente:
-- - 12 pagos de mensualidad (Enero a Diciembre)
-- - 1 pago de inscripción anual
-- - 1 pago de seguro + credencial

-- ============================================
-- FUNCIÓN PARA GENERAR PAGOS
-- ============================================
CREATE OR REPLACE FUNCTION generar_pagos_alumno()
RETURNS TRIGGER AS $$
DECLARE
  anio_actual INT;
  mes_num INT;
  nombre_mes TEXT;
  fecha_limite DATE;
BEGIN
  anio_actual := EXTRACT(YEAR FROM CURRENT_DATE);
  
  -- ============================================
  -- 1. PAGO DE INSCRIPCIÓN ANUAL
  -- ============================================
  INSERT INTO pagos (
    id,
    alumno_id,
    mes,
    concepto,
    monto,
    fecha_limite,
    pagado,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    NEW.id,
    'Inscripción ' || anio_actual,
    'Inscripción Anual',
    1500.00, -- Monto de inscripción
    CURRENT_DATE + INTERVAL '15 days', -- 15 días para pagar
    false,
    NOW(),
    NOW()
  );
  
  -- ============================================
  -- 2. PAGO DE SEGURO + CREDENCIAL (UNA SOLA VEZ)
  -- ============================================
  INSERT INTO pagos (
    id,
    alumno_id,
    mes,
    concepto,
    monto,
    fecha_limite,
    pagado,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    NEW.id,
    'Seguro ' || anio_actual,
    'Seguro + Credencial',
    300.00, -- Monto de seguro + credencial
    CURRENT_DATE + INTERVAL '15 days', -- 15 días para pagar
    false,
    NOW(),
    NOW()
  );
  
  -- ============================================
  -- 3. 12 PAGOS DE MENSUALIDAD (ENERO A DICIEMBRE)
  -- ============================================
  FOR mes_num IN 1..12 LOOP
    -- Determinar nombre del mes
    nombre_mes := CASE mes_num
      WHEN 1 THEN 'Enero'
      WHEN 2 THEN 'Febrero'
      WHEN 3 THEN 'Marzo'
      WHEN 4 THEN 'Abril'
      WHEN 5 THEN 'Mayo'
      WHEN 6 THEN 'Junio'
      WHEN 7 THEN 'Julio'
      WHEN 8 THEN 'Agosto'
      WHEN 9 THEN 'Septiembre'
      WHEN 10 THEN 'Octubre'
      WHEN 11 THEN 'Noviembre'
      WHEN 12 THEN 'Diciembre'
    END;
    
    -- Calcular fecha límite (día 5 de cada mes)
    fecha_limite := make_date(anio_actual, mes_num, 5);
    
    -- Si la fecha límite ya pasó este año, poner para el siguiente
    IF fecha_limite < CURRENT_DATE THEN
      fecha_limite := make_date(anio_actual + 1, mes_num, 5);
    END IF;
    
    -- Insertar pago mensual
    INSERT INTO pagos (
      id,
      alumno_id,
      mes,
      concepto,
      monto,
      fecha_limite,
      pagado,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      NEW.id,
      nombre_mes || ' ' || EXTRACT(YEAR FROM fecha_limite),
      'Mensualidad',
      2000.00, -- Monto de mensualidad
      fecha_limite,
      false,
      NOW(),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ELIMINAR TRIGGER ANTERIOR (SI EXISTE)
-- ============================================
DROP TRIGGER IF EXISTS trigger_generar_pagos_alumno ON alumnos;

-- ============================================
-- CREAR TRIGGER
-- ============================================
CREATE TRIGGER trigger_generar_pagos_alumno
  AFTER INSERT ON alumnos
  FOR EACH ROW
  EXECUTE FUNCTION generar_pagos_alumno();

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Ver si el trigger se creó correctamente
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_generar_pagos_alumno';

-- Debe mostrar:
-- trigger_generar_pagos_alumno | INSERT | alumnos | EXECUTE FUNCTION generar_pagos_alumno()

-- ============================================
-- PRUEBA (OPCIONAL)
-- ============================================
-- Para probar, puedes crear un alumno de prueba:
-- (Descomenta las siguientes líneas si quieres probarlo)

/*
INSERT INTO alumnos (
  id,
  nombre,
  apellidos,
  fecha_nacimiento,
  genero,
  padre_id,
  activo,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'Prueba',
  'Test',
  '2020-01-01',
  'niño',
  (SELECT id FROM usuarios WHERE rol = 'padre' LIMIT 1), -- Toma cualquier padre
  true,
  NOW(),
  NOW()
);

-- Luego verifica que se crearon 14 pagos:
SELECT concepto, mes, monto, fecha_limite 
FROM pagos 
WHERE alumno_id = (SELECT id FROM alumnos WHERE nombre = 'Prueba' ORDER BY created_at DESC LIMIT 1)
ORDER BY created_at;

-- Deberías ver:
-- 1. Inscripción Anual ($1,500)
-- 2. Seguro + Credencial ($300)
-- 3-14. Enero a Diciembre ($2,000 cada uno)
*/

-- ============================================
-- NOTAS IMPORTANTES:
-- ============================================
-- 1. Los montos pueden ajustarse según necesites:
--    - Inscripción: $1,500
--    - Seguro + Credencial: $300
--    - Mensualidad: $2,000
--
-- 2. Las fechas límite de mensualidad son día 5 de cada mes
--
-- 3. Si el alumno se crea en medio del año, los meses que ya pasaron
--    tendrán fecha límite para el siguiente año
--
-- 4. El trigger se ejecuta AUTOMÁTICAMENTE cada vez que se crea un alumno
