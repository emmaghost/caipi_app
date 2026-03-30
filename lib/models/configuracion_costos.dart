class ConfiguracionCostos {
  final String id;
  final double costoInscripcion;
  final double costoSeguroCredencial;
  final double costoMensualidad12;
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
    required this.costoMensualidad10,
    required this.vigente,
    required this.vigenciaDesde,
    this.vigenciaHasta,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConfiguracionCostos.fromJson(Map<String, dynamic> json) {
    return ConfiguracionCostos(
      id: json['id'] as String,
      costoInscripcion: (json['costo_inscripcion'] as num).toDouble(),
      costoSeguroCredencial: (json['costo_seguro_credencial'] as num).toDouble(),
      costoMensualidad12: (json['costo_mensualidad_12'] as num).toDouble(),
      costoMensualidad10: (json['costo_mensualidad_10'] as num).toDouble(),
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
      'costo_mensualidad_10': costoMensualidad10,
      'vigente': vigente,
      'vigencia_desde': vigenciaDesde.toIso8601String(),
      'vigencia_hasta': vigenciaHasta?.toIso8601String(),
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Total del plan de 12 meses
  double get totalPlan12 {
    return costoInscripcion + costoSeguroCredencial + (costoMensualidad12 * 12);
  }

  // Total del plan de 10 meses
  double get totalPlan10 {
    return costoInscripcion + costoSeguroCredencial + (costoMensualidad10 * 10);
  }
}
