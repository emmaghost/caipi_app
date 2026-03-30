class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fechaEvento;
  final String? horaInicio;
  final String? horaFin;
  final String? lugar;
  final String tipo; // 'academico', 'festivo', 'reunion', 'clausura', 'otro'
  final bool paraTodos;
  final List<String>? gradosIds;
  final String? fotoUrl;
  final String? creadoPor;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaEvento,
    this.horaInicio,
    this.horaFin,
    this.lugar,
    required this.tipo,
    this.paraTodos = true,
    this.gradosIds,
    this.fotoUrl,
    this.creadoPor,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      fechaEvento: DateTime.parse(json['fecha_evento']),
      horaInicio: json['hora_inicio'] as String?,
      horaFin: json['hora_fin'] as String?,
      lugar: json['lugar'] as String?,
      tipo: json['tipo'] as String,
      paraTodos: json['para_todos'] as bool? ?? true,
      gradosIds: json['grados_ids'] != null 
          ? List<String>.from(json['grados_ids'])
          : null,
      fotoUrl: json['foto_url'] as String?,
      creadoPor: json['creado_por'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_evento': fechaEvento.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'lugar': lugar,
      'tipo': tipo,
      'para_todos': paraTodos,
      'grados_ids': gradosIds,
      'foto_url': fotoUrl,
      'creado_por': creadoPor,
      'activo': activo,
    };
  }

  // Getter para verificar si el evento ya pasó
  bool get yaOcurrio => fechaEvento.isBefore(DateTime.now());

  // Getter para verificar si es hoy
  bool get esHoy {
    final ahora = DateTime.now();
    return fechaEvento.year == ahora.year &&
        fechaEvento.month == ahora.month &&
        fechaEvento.day == ahora.day;
  }

  // Getter para verificar si es próximo (dentro de 7 días)
  bool get esProximo {
    final ahora = DateTime.now();
    final diferencia = fechaEvento.difference(ahora).inDays;
    return diferencia >= 0 && diferencia <= 7;
  }

  // Getter para emoji según tipo
  String get emoji {
    switch (tipo) {
      case 'academico':
        return '📚';
      case 'festivo':
        return '🎉';
      case 'reunion':
        return '👥';
      case 'clausura':
        return '🎓';
      default:
        return '📅';
    }
  }
}
