// Constantes de la aplicación

class Constantes {
  // Grados disponibles
  static const List<String> grados = [
    '1ro A', '1ro B',
    '2do A', '2do B',
    '3ro A', '3ro B',
    '4to A', '4to B',
    '5to A', '5to B',
    '6to A', '6to B',
  ];

  static const String especialidadTitular = 'titular';
  static const String especialidadIngles = 'ingles';
  static const String materiaIngles = 'Inglés';

  // Materias
  static const List<String> materias = [
    'Español',
    'Matemáticas',
    'Ciencias Naturales',
    'Historia',
    'Geografía',
    'Formación Cívica y Ética',
    'Educación Física',
    'Artes',
    materiaIngles,
  ];

  // Periodos escolares
  static const List<String> periodos = [
    '1er Bimestre 2026',
    '2do Bimestre 2026',
    '3er Bimestre 2026',
    '4to Bimestre 2026',
    '5to Bimestre 2026',
  ];

  // Monto de colegiatura por defecto
  static const double montoColegiatura = 500.0;

  /// Si es false, nadie ve beca. Si es true, solo la directora.
  static const bool mostrarCampoBeca = true;

  /// Cuentas destino al acreditar un pago (campo recibido_por_nombre en BD).
  static const List<String> opcionesPagadoA = [
    'BBVA Santiago Gómez',
    'BBVA Instituto Brain',
    'Efectivo',
  ];

  // Conceptos de pago
  static const List<String> conceptosPago = [
    'Colegiatura',
    'Inscripción',
    'Material escolar',
    'Uniforme',
    'Transporte',
    'Actividades extraescolares',
    'Otro',
  ];
}
