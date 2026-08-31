class SolicitudRecogida {
  final String id;
  final String alumnoId;
  final String padreId;
  final String estado;
  final String? mensaje;
  final DateTime createdAt;
  final DateTime? atendidaAt;
  final String? atendidaPor;

  SolicitudRecogida({
    required this.id,
    required this.alumnoId,
    required this.padreId,
    this.estado = 'pendiente',
    this.mensaje,
    required this.createdAt,
    this.atendidaAt,
    this.atendidaPor,
  });

  bool get esPendiente => estado == 'pendiente';

  factory SolicitudRecogida.fromJson(Map<String, dynamic> json) {
    return SolicitudRecogida(
      id: json['id'] as String,
      alumnoId: json['alumno_id'] as String,
      padreId: json['padre_id'] as String,
      estado: json['estado'] as String? ?? 'pendiente',
      mensaje: json['mensaje'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      atendidaAt: json['atendida_at'] != null
          ? DateTime.parse(json['atendida_at'] as String)
          : null,
      atendidaPor: json['atendida_por'] as String?,
    );
  }
}
