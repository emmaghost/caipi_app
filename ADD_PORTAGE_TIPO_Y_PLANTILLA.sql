-- =============================================================================
-- PORTAGE: tipo lista (habilidades | alertas) + plantilla 5 áreas Viri
-- Ejecutar en Supabase → SQL Editor
-- =============================================================================

ALTER TABLE public.portage_listas
  ADD COLUMN IF NOT EXISTS tipo TEXT NOT NULL DEFAULT 'habilidades';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'portage_listas_tipo_check'
  ) THEN
    ALTER TABLE public.portage_listas
      ADD CONSTRAINT portage_listas_tipo_check
      CHECK (tipo IN ('habilidades', 'alertas'));
  END IF;
END $$;

COMMENT ON COLUMN public.portage_listas.tipo IS
  'habilidades = lo que el niño debe lograr; alertas = señales atípicas';

-- Plantilla de habilidades (se aplica al grado activo que elijas abajo).
-- Cambia el filtro del grado si quieres otra base (por defecto Kinder 1 o el primero).
DO $$
DECLARE
  v_grado uuid;
  v_lista uuid;
  v_orden int;
  r record;
BEGIN
  SELECT id INTO v_grado
  FROM public.grados
  WHERE activo = true AND nombre ILIKE '%kinder 1%'
  ORDER BY nombre
  LIMIT 1;

  IF v_grado IS NULL THEN
    SELECT id INTO v_grado FROM public.grados WHERE activo = true ORDER BY nombre LIMIT 1;
  END IF;

  IF v_grado IS NULL THEN
    RAISE NOTICE 'Sin grados activos: plantilla no insertada.';
    RETURN;
  END IF;

  -- Evitar duplicar si ya hay listas de habilidades en ese grado
  IF EXISTS (
    SELECT 1 FROM public.portage_listas
    WHERE grado_id = v_grado AND tipo = 'habilidades'
      AND nombre ILIKE 'Desarrollo Motor Grueso'
  ) THEN
    RAISE NOTICE 'Plantilla ya existe en grado %.', v_grado;
    RETURN;
  END IF;

  FOR r IN
    SELECT * FROM (VALUES
      (1, 'Desarrollo Motor Grueso', ARRAY[
        'Saltar hacia adelante con ambos pies juntos a una distancia de al menos 10 a 20 cm.',
        'Subir escaleras alternando los pies (un pie por escalón) con apoyo o sujeción.',
        'Mantenerse en un solo pie durante 1 a 2 segundos sin perder el equilibrio.',
        'Caminar sobre una línea recta trazada en el piso manteniendo la dirección.',
        'Dar patadas con fuerza a una pelota en movimiento hacia una dirección determinada.',
        'Agacharse y levantarse con agilidad mientras sostiene un objeto pesado o grande entre las manos.'
      ]::text[]),
      (2, 'Desarrollo Motor Fino', ARRAY[
        'Construir torres estables de 6 a 8 bloques o cubos.',
        'Imitar el trazo de un círculo (garabato circular cerrado) y líneas verticales/horizontales continuas.',
        'Enhebrar cuentas o cuentas de madera grandes en un cordón o agujeta gruesa.',
        'Manipular tijeras infantiles para realizar pequeños cortes o picados en la orilla del papel.',
        'Desabrochar botones grandes o aflojar cierres de presión.',
        'Desenroscar tapaderas de frascos con movimiento de muñeca coordinado.'
      ]::text[]),
      (3, 'Desarrollo Cognitivo', ARRAY[
        'Clasificar objetos por dos atributos visuales básicos (por ejemplo, agrupar por color o por tamaño).',
        'Emparejar e identificar objetos iguales o imágenes idénticas en tarjetas.',
        'Comprender conceptos de cantidad iniciales (''uno'' frente a ''muchos'').',
        'Completar rompecabezas de corte recto o encajes de 3 a 4 piezas con marco.',
        'Identificar conceptos espaciales básicos (arriba/abajo, dentro/fuera, adelante/atrás).',
        'Ejecutar secuencias de juego simbólico más detalladas (ej. curar a un juguete con un kit de doctor, servir la mesa para una fiesta de té).'
      ]::text[]),
      (4, 'Lenguaje y Comunicación', ARRAY[
        'Formar frases complejas de 3 a 4 palabras (''Quiero más leche, por favor'', ''Papá fue a trabajar'').',
        'Comprender y responder a preguntas sencillas con ''¿Qué?'', ''¿Dónde?'' y ''¿Quién?''.',
        'Utilizar pronombres personales de forma más consistente (''yo'', ''tú'', ''mío'', ''él/ella'').',
        'Articular un vocabulario activo de aproximadamente 100 a 200 palabras reconocibles.',
        'Entender conceptos de tamaño relativo en el habla (''grande'' / ''pequeño'').',
        'Cantar o repetir fragmentos de canciones infantiles y rimas sencillas.'
      ]::text[]),
      (5, 'Socialización y Autoayuda (Autonomía)', ARRAY[
        'Participar activamente en el proceso de entrenamiento de esfínteres (avisa con anticipación cuándo quiere ir al baño o expresa incomodidad).',
        'Lavarse y secarse las manos con mínima asistencia de un adulto.',
        'Ponerse prendas de vestir sencillas de forma independiente (pantalones de resorte, calcetines sueltos, zapatos con velcro).',
        'Usar la cuchara y el tenedor de forma limpia sin derramar la mayor parte de los alimentos.',
        'Defender sus pertenencias y juguetes diciendo ''mío'', aunque empieza a aceptar compartir bajo la guía de un adulto.',
        'Expresar verbalmente o mediante gestos una variedad de emociones (alegría, enojo, tristeza, frustración).'
      ]::text[])
    ) AS t(ord, nombre, items)
    ORDER BY ord
  LOOP
    INSERT INTO public.portage_listas (grado_id, nombre, activa, tipo)
    VALUES (v_grado, r.nombre, true, 'habilidades')
    RETURNING id INTO v_lista;

    v_orden := 0;
    FOR v_orden IN 1 .. array_length(r.items, 1) LOOP
      INSERT INTO public.portage_indicadores (lista_id, nombre, orden)
      VALUES (v_lista, r.items[v_orden], v_orden - 1);
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Plantilla 5 listas de habilidades creada en grado %.', v_grado;
END $$;
