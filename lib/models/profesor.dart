class Profesor {
  final String id;
  final String usuarioId;
  final String? gradoId;
  final String? especialidad;
  final DateTime? fechaIngreso;
  final bool activo;
  final DateTime createdAt;

  Profesor({
    required this.id,
    required this.usuarioId,
    this.gradoId,
    this.especialidad,
    this.fechaIngreso,
    this.activo = true,
    required this.createdAt,
  });

  factory Profesor.fromJson(Map<String, dynamic> json) {
    return Profesor(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      gradoId: json['grado_id'] as String?,
      especialidad: json['especialidad'] as String?,
      fechaIngreso: json['fecha_ingreso'] != null 
          ? DateTime.parse(json['fecha_ingreso']) 
          : null,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'grado_id': gradoId,
      'especialidad': especialidad,
      'fecha_ingreso': fechaIngreso?.toIso8601String(),
      'activo': activo,
    };
  }
}
