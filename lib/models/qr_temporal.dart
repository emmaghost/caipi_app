// Modelo para QR Temporal (un solo uso)

class QrTemporal {
  final String id;
  final String codigo;
  final String personaAutorizadaId;
  final String alumnoId;
  final String? generadoPor;
  final DateTime fechaGeneracion;
  final DateTime fechaExpiracion;
  final bool usado;
  final DateTime? fechaUso;
  final String? usadoPor;
  final bool activo;
  final String? notas;
  final DateTime createdAt;

  QrTemporal({
    required this.id,
    required this.codigo,
    required this.personaAutorizadaId,
    required this.alumnoId,
    this.generadoPor,
    required this.fechaGeneracion,
    required this.fechaExpiracion,
    this.usado = false,
    this.fechaUso,
    this.usadoPor,
    this.activo = true,
    this.notas,
    required this.createdAt,
  });

  /// ¿Está expirado?
  bool get estaExpirado {
    return DateTime.now().isAfter(fechaExpiracion);
  }

  /// ¿Está disponible?
  bool get estaDisponible {
    return activo && !usado && !estaExpirado;
  }

  /// Tiempo restante en horas
  int get horasRestantes {
    if (estaExpirado) return 0;
    return fechaExpiracion.difference(DateTime.now()).inHours;
  }

  factory QrTemporal.fromJson(Map<String, dynamic> json) {
    return QrTemporal(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      personaAutorizadaId: json['persona_autorizada_id'] as String,
      alumnoId: json['alumno_id'] as String,
      generadoPor: json['generado_por'] as String?,
      fechaGeneracion: DateTime.parse(json['fecha_generacion'] as String),
      fechaExpiracion: DateTime.parse(json['fecha_expiracion'] as String),
      usado: json['usado'] as bool? ?? false,
      fechaUso: json['fecha_uso'] != null
          ? DateTime.parse(json['fecha_uso'] as String)
          : null,
      usadoPor: json['usado_por'] as String?,
      activo: json['activo'] as bool? ?? true,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'persona_autorizada_id': personaAutorizadaId,
      'alumno_id': alumnoId,
      'generado_por': generadoPor,
      'fecha_generacion': fechaGeneracion.toIso8601String(),
      'fecha_expiracion': fechaExpiracion.toIso8601String(),
      'usado': usado,
      'fecha_uso': fechaUso?.toIso8601String(),
      'usado_por': usadoPor,
      'activo': activo,
      'notas': notas,
    };
  }
}
