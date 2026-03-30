class ClaseExtracurricular {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? profesorId;
  final List<String> diasSemana;
  final DateTime? horaInicio;
  final DateTime? horaFin;
  final double? costoMensual;
  final int cupoMaximo;
  final bool permiteExternos;
  final bool activo;
  final DateTime createdAt;

  ClaseExtracurricular({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.profesorId,
    this.diasSemana = const [],
    this.horaInicio,
    this.horaFin,
    this.costoMensual,
    this.cupoMaximo = 15,
    this.permiteExternos = false,
    this.activo = true,
    required this.createdAt,
  });

  String get horario {
    if (horaInicio == null || horaFin == null) return 'Por definir';
    return '${_formatTime(horaInicio!)} - ${_formatTime(horaFin!)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  factory ClaseExtracurricular.fromJson(Map<String, dynamic> json) {
    return ClaseExtracurricular(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      profesorId: json['profesor_id'] as String?,
      diasSemana: json['dias_semana'] != null
          ? List<String>.from(json['dias_semana'])
          : [],
      horaInicio: json['hora_inicio'] != null
          ? DateTime.parse('2000-01-01 ${json['hora_inicio']}')
          : null,
      horaFin: json['hora_fin'] != null
          ? DateTime.parse('2000-01-01 ${json['hora_fin']}')
          : null,
      costoMensual: json['costo_mensual'] != null
          ? double.parse(json['costo_mensual'].toString())
          : null,
      cupoMaximo: json['cupo_maximo'] as int? ?? 15,
      permiteExternos: json['permite_externos'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'profesor_id': profesorId,
      'dias_semana': diasSemana,
      'hora_inicio': horaInicio?.toIso8601String().split('T')[1],
      'hora_fin': horaFin?.toIso8601String().split('T')[1],
      'costo_mensual': costoMensual,
      'cupo_maximo': cupoMaximo,
      'permite_externos': permiteExternos,
      'activo': activo,
    };
  }
}
