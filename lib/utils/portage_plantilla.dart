/// Plantilla de listas de desarrollo (habilidades) — contenido Viri / CAIPI.
/// Usado al cargar plantilla desde la app; el SQL ADD_PORTAGE_TIPO_Y_PLANTILLA
/// también inserta lo mismo en BD.
class PortagePlantilla {
  PortagePlantilla._();

  static const tipoHabilidades = 'habilidades';
  static const tipoAlertas = 'alertas';

  /// 5 áreas × 6 indicadores cada una.
  static const List<({String nombre, List<String> items})> habilidades = [
    (
      nombre: 'Desarrollo Motor Grueso',
      items: [
        'Saltar hacia adelante con ambos pies juntos a una distancia de al menos 10 a 20 cm.',
        'Subir escaleras alternando los pies (un pie por escalón) con apoyo o sujeción.',
        'Mantenerse en un solo pie durante 1 a 2 segundos sin perder el equilibrio.',
        'Caminar sobre una línea recta trazada en el piso manteniendo la dirección.',
        'Dar patadas con fuerza a una pelota en movimiento hacia una dirección determinada.',
        'Agacharse y levantarse con agilidad mientras sostiene un objeto pesado o grande entre las manos.',
      ],
    ),
    (
      nombre: 'Desarrollo Motor Fino',
      items: [
        'Construir torres estables de 6 a 8 bloques o cubos.',
        'Imitar el trazo de un círculo (garabato circular cerrado) y líneas verticales/horizontales continuas.',
        'Enhebrar cuentas o cuentas de madera grandes en un cordón o agujeta gruesa.',
        'Manipular tijeras infantiles para realizar pequeños cortes o picados en la orilla del papel.',
        'Desabrochar botones grandes o aflojar cierres de presión.',
        'Desenroscar tapaderas de frascos con movimiento de muñeca coordinado.',
      ],
    ),
    (
      nombre: 'Desarrollo Cognitivo',
      items: [
        'Clasificar objetos por dos atributos visuales básicos (por ejemplo, agrupar por color o por tamaño).',
        'Emparejar e identificar objetos iguales o imágenes idénticas en tarjetas.',
        "Comprender conceptos de cantidad iniciales ('uno' frente a 'muchos').",
        'Completar rompecabezas de corte recto o encajes de 3 a 4 piezas con marco.',
        'Identificar conceptos espaciales básicos (arriba/abajo, dentro/fuera, adelante/atrás).',
        'Ejecutar secuencias de juego simbólico más detalladas (ej. curar a un juguete con un kit de doctor, servir la mesa para una fiesta de té).',
      ],
    ),
    (
      nombre: 'Lenguaje y Comunicación',
      items: [
        "Formar frases complejas de 3 a 4 palabras ('Quiero más leche, por favor', 'Papá fue a trabajar').",
        "Comprender y responder a preguntas sencillas con '¿Qué?', '¿Dónde?' y '¿Quién?'.",
        "Utilizar pronombres personales de forma más consistente ('yo', 'tú', 'mío', 'él/ella').",
        'Articular un vocabulario activo de aproximadamente 100 a 200 palabras reconocibles.',
        "Entender conceptos de tamaño relativo en el habla ('grande' / 'pequeño').",
        'Cantar o repetir fragmentos de canciones infantiles y rimas sencillas.',
      ],
    ),
    (
      nombre: 'Socialización y Autoayuda (Autonomía)',
      items: [
        'Participar activamente en el proceso de entrenamiento de esfínteres (avisa con anticipación cuándo quiere ir al baño o expresa incomodidad).',
        'Lavarse y secarse las manos con mínima asistencia de un adulto.',
        'Ponerse prendas de vestir sencillas de forma independiente (pantalones de resorte, calcetines sueltos, zapatos con velcro).',
        'Usar la cuchara y el tenedor de forma limpia sin derramar la mayor parte de los alimentos.',
        "Defender sus pertenencias y juguetes diciendo 'mío', aunque empieza a aceptar compartir bajo la guía de un adulto.",
        'Expresar verbalmente o mediante gestos una variedad de emociones (alegría, enojo, tristeza, frustración).',
      ],
    ),
  ];

  /// Ejemplos iniciales de alertas (señales atípicas). La directora puede editar.
  static const List<String> alertasEjemplo = [
    'Sus ojos se cruzan de forma frecuente o persistente.',
    'Presenta convulsiones o movimientos involuntarios bruscos.',
    'Sus manos o cuerpo tiemblan en reposo o al sostener objetos.',
    'No responde a sonidos fuertes o a su nombre de forma consistente.',
    'Pierde habilidades que ya había logrado (regresión).',
  ];
}
