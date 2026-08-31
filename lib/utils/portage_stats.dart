import '../models/portage.dart';

/// Conteo de indicadores por estado para una evaluación y alumno.
class PortageConteoEstado {
  final int logrados;
  final int enProceso;
  final int sinCalificar;
  final int total;

  const PortageConteoEstado({
    required this.logrados,
    required this.enProceso,
    required this.sinCalificar,
    required this.total,
  });
}

/// Punto de serie temporal para gráficas (una evaluación).
class PortagePuntoSerie {
  final DateTime fecha;
  final int logrados;
  final int enProceso;
  final int sinCalificar;
  final int total;

  const PortagePuntoSerie({
    required this.fecha,
    required this.logrados,
    required this.enProceso,
    required this.sinCalificar,
    required this.total,
  });

  Map<String, dynamic> toChartMap() => {
        'fecha': fecha,
        'logrados': logrados,
        'enProceso': enProceso,
        'sinCalificar': sinCalificar,
        'total': total,
      };
}

/// Funciones puras para estadísticas Portage (gráficas y resúmenes).
class PortageStats {
  PortageStats._();

  /// Cuenta logrados / en proceso / sin calificar para una evaluación y alumno.
  static PortageConteoEstado contarPorEstado({
    required Iterable<PortageResultado> resultados,
    required int totalIndicadores,
  }) {
    if (totalIndicadores < 0) {
      throw ArgumentError('totalIndicadores no puede ser negativo');
    }

    var logrados = 0;
    var enProceso = 0;
    for (final r in resultados) {
      if (r.esLogrado) {
        logrados++;
      } else if (r.esEnProceso) {
        enProceso++;
      }
    }

    final calificados = logrados + enProceso;
    final sinCalificar = (totalIndicadores - calificados).clamp(0, totalIndicadores);

    return PortageConteoEstado(
      logrados: logrados,
      enProceso: enProceso,
      sinCalificar: sinCalificar,
      total: totalIndicadores,
    );
  }

  /// Ventanas soportadas en meses para la gráfica de evolución.
  static const ventanasMeses = [1, 3, 6];

  static bool ventanaValida(int meses) => ventanasMeses.contains(meses);

  /// Fecha límite: evaluaciones con `fechaInicio >= limite` entran en la ventana.
  static DateTime limiteVentanaMeses(DateTime ahora, int meses) {
    if (!ventanaValida(meses)) {
      throw ArgumentError('meses debe ser 1, 3 o 6');
    }
    return DateTime(ahora.year, ahora.month - meses, ahora.day);
  }

  /// Serie temporal filtrada: evaluaciones con fecha_inicio dentro de los últimos [meses].
  static List<PortagePuntoSerie> seriePorVentanaMeses({
    required List<PortageEvaluacion> evaluaciones,
    required Map<String, List<PortageResultado>> resultadosPorEvaluacion,
    required Map<String, int> totalIndicadoresPorEvaluacion,
    required int meses,
    DateTime? ahora,
  }) {
    final ref = ahora ?? DateTime.now();
    final limite = limiteVentanaMeses(ref, meses);

    final filtradas = evaluaciones
        .where((e) => !_soloFecha(e.fechaInicio).isBefore(_soloFecha(limite)))
        .toList()
      ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

    return filtradas.map((evaluacion) {
      final total = totalIndicadoresPorEvaluacion[evaluacion.id] ?? 0;
      final resultados = resultadosPorEvaluacion[evaluacion.id] ?? const [];
      final conteo = contarPorEstado(
        resultados: resultados,
        totalIndicadores: total,
      );
      return PortagePuntoSerie(
        fecha: _soloFecha(evaluacion.fechaInicio),
        logrados: conteo.logrados,
        enProceso: conteo.enProceso,
        sinCalificar: conteo.sinCalificar,
        total: conteo.total,
      );
    }).toList();
  }

  /// Descripción ASCII simple para PDF o texto (barras proporcionales).
  static String barrasAscii(PortageConteoEstado conteo, {int ancho = 20}) {
    if (conteo.total <= 0) return '(sin indicadores)';
    final escala = ancho / conteo.total;
    final l = (conteo.logrados * escala).round();
    final e = (conteo.enProceso * escala).round();
    final s = ancho - l - e;
    return '${'L' * l}${'E' * e}${'-' * s.clamp(0, ancho)} '
        '(${conteo.logrados}L · ${conteo.enProceso}EP · ${conteo.sinCalificar}—)';
  }

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);
}
