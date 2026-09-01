import '../utils/pago_helpers.dart';

class ConfiguracionCostos {
  final String id;
  final double costoInscripcion;
  final double costoSeguroCredencial;
  final double costoMensualidad12;
  final double costoMensualidad11;
  final double costoMensualidad10;
  /// Pago único del ciclo (si es null, se usa mensualidad × meses).
  final double? costoAnticipado12;
  final double? costoAnticipado11;
  final double? costoAnticipado10;
  /// Total si se paga mes a mes (si es null, se usa mensualidad × meses).
  final double? costoRecargo12;
  final double? costoRecargo11;
  final double? costoRecargo10;
  final bool vigente;
  final DateTime vigenciaDesde;
  final DateTime? vigenciaHasta;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConfiguracionCostos({
    required this.id,
    required this.costoInscripcion,
    required this.costoSeguroCredencial,
    required this.costoMensualidad12,
    required this.costoMensualidad11,
    required this.costoMensualidad10,
    this.costoAnticipado12,
    this.costoAnticipado11,
    this.costoAnticipado10,
    this.costoRecargo12,
    this.costoRecargo11,
    this.costoRecargo10,
    required this.vigente,
    required this.vigenciaDesde,
    this.vigenciaHasta,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
  });

  static double? _optDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  factory ConfiguracionCostos.fromJson(Map<String, dynamic> json) {
    final m12 = (json['costo_mensualidad_12'] as num).toDouble();
    final m10 = (json['costo_mensualidad_10'] as num).toDouble();
    final m11Raw = json['costo_mensualidad_11'];
    final m11 = m11Raw is num ? m11Raw.toDouble() : ((m12 + m10) / 2);

    return ConfiguracionCostos(
      id: json['id'] as String,
      costoInscripcion: (json['costo_inscripcion'] as num).toDouble(),
      costoSeguroCredencial: (json['costo_seguro_credencial'] as num).toDouble(),
      costoMensualidad12: m12,
      costoMensualidad11: m11,
      costoMensualidad10: m10,
      costoAnticipado12: _optDouble(json['costo_anticipado_12']),
      costoAnticipado11: _optDouble(json['costo_anticipado_11']),
      costoAnticipado10: _optDouble(json['costo_anticipado_10']),
      costoRecargo12: _optDouble(json['costo_recargo_12']),
      costoRecargo11: _optDouble(json['costo_recargo_11']),
      costoRecargo10: _optDouble(json['costo_recargo_10']),
      vigente: json['vigente'] as bool,
      vigenciaDesde: DateTime.parse(json['vigencia_desde'] as String),
      vigenciaHasta: json['vigencia_hasta'] != null
          ? DateTime.parse(json['vigencia_hasta'] as String)
          : null,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'costo_inscripcion': costoInscripcion,
      'costo_seguro_credencial': costoSeguroCredencial,
      'costo_mensualidad_12': costoMensualidad12,
      'costo_mensualidad_11': costoMensualidad11,
      'costo_mensualidad_10': costoMensualidad10,
      'costo_anticipado_12': costoAnticipado12,
      'costo_anticipado_11': costoAnticipado11,
      'costo_anticipado_10': costoAnticipado10,
      'costo_recargo_12': costoRecargo12,
      'costo_recargo_11': costoRecargo11,
      'costo_recargo_10': costoRecargo10,
      'vigente': vigente,
      'vigencia_desde': vigenciaDesde.toIso8601String(),
      'vigencia_hasta': vigenciaHasta?.toIso8601String(),
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double mensualidadDePlan(int planPagos) {
    switch (planPagos) {
      case 10:
        return costoMensualidad10;
      case 11:
        return costoMensualidad11;
      default:
        return costoMensualidad12;
    }
  }

  // Totales solo colegiaturas (inscripción/seguro no entran en la suma)
  double get totalPlan12 => PagoHelpers.totalColegiaturas(costoMensualidad12, 12);

  double get totalPlan11 => PagoHelpers.totalColegiaturas(costoMensualidad11, 11);

  double get totalPlan10 => PagoHelpers.totalColegiaturas(costoMensualidad10, 10);

  double anticipadoDePlan(int meses) {
    return PagoHelpers.montoPlanOCalculado(
      configurado: switch (meses) {
        10 => costoAnticipado10,
        11 => costoAnticipado11,
        _ => costoAnticipado12,
      },
      mensualidad: mensualidadDePlan(meses),
      meses: meses,
    );
  }

  double recargoDePlan(int meses) {
    return PagoHelpers.montoPlanOCalculado(
      configurado: switch (meses) {
        10 => costoRecargo10,
        11 => costoRecargo11,
        _ => costoRecargo12,
      },
      mensualidad: mensualidadDePlan(meses),
      meses: meses,
    );
  }

  double totalMostrado({
    required int meses,
    bool sumarInscripcion = false,
    bool sumarSeguro = false,
  }) {
    return PagoHelpers.totalPlanMostrado(
      mensualidad: mensualidadDePlan(meses),
      meses: meses,
      inscripcion: costoInscripcion,
      seguro: costoSeguroCredencial,
      sumarInscripcion: sumarInscripcion,
      sumarSeguro: sumarSeguro,
    );
  }
}
