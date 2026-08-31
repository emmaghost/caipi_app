class ConfiguracionCostos {
  final String id;
  final double costoInscripcion;
  final double costoSeguroCredencial;
  final double costoMensualidad12;
  final double costoMensualidad11;
  final double costoMensualidad10;
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
    required this.vigente,
    required this.vigenciaDesde,
    this.vigenciaHasta,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
  });

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
  double get totalPlan12 => costoMensualidad12 * 12;

  double get totalPlan11 => costoMensualidad11 * 11;

  double get totalPlan10 => costoMensualidad10 * 10;
}
