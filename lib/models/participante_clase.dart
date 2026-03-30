class ParticipanteClase {
  final String id;
  final String claseId;
  final String? alumnoId;
  final String tipoParticipante; // 'alumno' o 'externo'
  final String? nombreExterno;
  final String? apellidosExterno;
  final String? telefonoExterno;
  final String? emailExterno;
  final DateTime fechaInscripcion;
  final bool activo;
  final DateTime createdAt;

  ParticipanteClase({
    required this.id,
    required this.claseId,
    this.alumnoId,
    required this.tipoParticipante,
    this.nombreExterno,
    this.apellidosExterno,
    this.telefonoExterno,
    this.emailExterno,
    required this.fechaInscripcion,
    this.activo = true,
    required this.createdAt,
  });

  bool get esAlumno => tipoParticipante == 'alumno';
  bool get esExterno => tipoParticipante == 'externo';

  String get nombreCompleto {
    if (esExterno && nombreExterno != null) {
      return '$nombreExterno ${apellidosExterno ?? ''}';
    }
    return 'Alumno';
  }

  factory ParticipanteClase.fromJson(Map<String, dynamic> json) {
    return ParticipanteClase(
      id: json['id'] as String,
      claseId: json['clase_id'] as String,
      alumnoId: json['alumno_id'] as String?,
      tipoParticipante: json['tipo_participante'] as String,
      nombreExterno: json['nombre_externo'] as String?,
      apellidosExterno: json['apellidos_externo'] as String?,
      telefonoExterno: json['telefono_externo'] as String?,
      emailExterno: json['email_externo'] as String?,
      fechaInscripcion: DateTime.parse(json['fecha_inscripcion']),
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clase_id': claseId,
      'alumno_id': alumnoId,
      'tipo_participante': tipoParticipante,
      'nombre_externo': nombreExterno,
      'apellidos_externo': apellidosExterno,
      'telefono_externo': telefonoExterno,
      'email_externo': emailExterno,
      'fecha_inscripcion': fechaInscripcion.toIso8601String().split('T')[0],
      'activo': activo,
    };
  }
}
